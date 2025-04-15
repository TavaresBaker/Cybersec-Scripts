#!/bin/bash
# Clean ShellHunter - Final version with no "not found" clutter

echo "[*] Starting scan for suspicious shell activity..."

# 1. Suspicious processes
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink -f "/proc/$pid/exe" 2>/dev/null)
    if [[ -n "$exe_path" && -e "$exe_path" ]]; then
        echo "[Weird Process] $exe_path"
    fi
done

# 2. Suspicious listening ports
netstat -tulpn 2>/dev/null | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)' | while read -r line; do
    echo "[Reverse Shell Port] $line"
done

# 3. Suspicious script contents
grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' /home /tmp /var/tmp 2>/dev/null | cut -d: -f1 | sort -u | while read -r filepath; do
    if [[ -f "$filepath" ]]; then
        echo "[Suspicious Script] $filepath"
    fi
done

# 4. Suspicious startup files
find /etc/systemd /etc/init.d ~/.config/autostart -type f 2>/dev/null | while read -r startup; do
    if grep -qiE 'python|nc|bash|sh' "$startup"; then
        echo "[Startup File] $startup"
    fi
done

echo "[✓] Scan done."
