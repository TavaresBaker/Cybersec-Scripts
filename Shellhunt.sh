#!/bin/sh
# Clean ShellHunter - pfSense-compatible with empty results messaging

echo "[*] Starting scan for suspicious shell activity..."

# 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
found_process=0
ps aux | grep -E '\b(nc|netcat|bash|sh|python|perl|php|ruby|socat)\b' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(ls -l /proc/$pid/file 2>/dev/null | awk '{print $NF}')
    if [ -n "$exe_path" ]; then
        echo "[Weird Process] PID: $pid | Executable: $exe_path"
        found_process=1
    fi
done
[ "$found_process" -eq 0 ] && echo "[OK] No suspicious processes found."

# 2. Suspicious listening ports
echo "[*] Scanning for known reverse shell ports..."
found_ports=0
sockstat -l | grep -E ':(4444|1337|1234|9001|2222|8080)' | while read -r line; do
    echo "[Reverse Shell Port] $line"
    found_ports=1
done
[ "$found_ports" -eq 0 ] && echo "[OK] No suspicious ports found."

# 3. Suspicious script contents
echo "[*] Searching for suspicious content in scripts..."
found_scripts=0
find /home /tmp /var/tmp -type f -name "*.sh" 2>/dev/null | while read -r script; do
    if grep -qE 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$script"; then
        echo "[Suspicious Script] $script"
        found_scripts=1
    fi
done
[ "$found_scripts" -eq 0 ] && echo "[OK] No suspicious scripts found."

# 4. Suspicious startup files
echo "[*] Checking suspicious startup entries..."
found_startup=0
find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart -type f 2>/dev/null | while read -r startup; do
    if grep -qiE '\b(python|nc|bash|sh)\b' "$startup"; then
        echo "[Startup File] $startup"
        found_startup=1
    fi
done
[ "$found_startup" -eq 0 ] && echo "[OK] No suspicious startup entries found."

echo "[✓] Scan complete."
