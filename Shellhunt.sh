#!/bin/sh
# Clean ShellHunter - Reverse Shell Detection

echo "[*] Starting scan for suspicious shell activity..."

### 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
found=0
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/file" 2>/dev/null)
    if [ -n "$exe_path" ]; then
        echo "[Weird Process] $exe_path"
        found=1
    fi
done
if [ "$found" -eq 0 ]; then
    echo "[OK] No suspicious processes found."
fi

### 2. Suspicious listening ports
echo "[*] Checking for suspicious listening ports..."
found=0
netstat -an | grep -E 'LISTEN' | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)' | while read -r line; do
    echo "[Reverse Shell Port] $line"
    found=1
done
if [ "$found" -eq 0 ]; then
    echo "[OK] No suspicious ports found."
fi

### 3. Suspicious script contents
echo "[*] Checking for suspicious script contents..."
found=0
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null | while read -r match; do
        filepath=$(echo "$match" | cut -d: -f1)
        echo "[Suspicious Script] $filepath"
        found=1
    done
done
if [ "$found" -eq 0 ]; then
    echo "[OK] No suspicious script contents found."
fi

### 4. Suspicious startup entries
echo "[*] Checking for suspicious startup entries..."
found=0
find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart 2>/dev/null | while read -r startup; do
    if [ -f "$startup" ] && grep -qEi '\b(nc|python|perl|php|ruby|socat)\b' "$startup"; then
        echo "[Startup File] $startup"
        found=1
    fi
done
if [ "$found" -eq 0 ]; then
    echo "[OK] No suspicious startup entries found."
fi

echo "[✓] Scan complete."
