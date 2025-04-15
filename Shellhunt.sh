#!/bin/bash
# ShellHunter.sh - Detect reverse shells and suspicious shell processes

echo "[*] Scanning for potential reverse shells and suspicious activity..."

echo -e "\n[+] Step 1: Checking for suspicious processes..."
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink -f "/proc/$pid/exe" 2>/dev/null)
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    
    if [[ -n "$exe_path" ]]; then
        echo -e "\n[*] PID: $pid"
        echo "[+] Executable: $exe_path"
        echo "[+] Command Line: $cmdline"
    fi
done

echo -e "\n[+] Step 2: Checking for suspicious network connections..."
netstat -tulpn 2>/dev/null | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)' || echo "[*] No known reverse shell ports detected."

echo -e "\n[+] Step 3: Looking for shell scripts with potential reverse shell code..."
grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|exec|/dev/tcp|0<&1|>&' /home /tmp /var/tmp 2>/dev/null | while read -r match; do
    echo "[!] Suspicious script content found: $match"
done

echo -e "\n[+] Step 4: Checking for rogue startup entries..."
find /etc/systemd /etc/init.d ~/.config/autostart -type f 2>/dev/null | while read -r startup; do
    if grep -qi 'python\|nc\|bash\|sh' "$startup"; then
        echo "[!] Suspicious startup file: $startup"
    fi
done

echo -e "\n[✓] Scan complete."
