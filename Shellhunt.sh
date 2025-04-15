#!/bin/sh
# Clean ShellHunter - Reverse Shell Detection

echo "[*] Starting scan for suspicious shell activity..."

### 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
processes=$(ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep)
if [ -n "$processes" ]; then
    echo "$processes" | while read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        exe_path=$(readlink "/proc/$pid/file" 2>/dev/null)
        if [ -n "$exe_path" ]; then
            echo "[Weird Process] $exe_path"
        fi
    done
fi

### 2. Suspicious listening ports
echo "[*] Checking for suspicious listening ports..."
ports=$(netstat -an | grep -E 'LISTEN' | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)')
if [ -n "$ports" ]; then
    echo "$ports" | while read -r line; do
        echo "[Reverse Shell Port] $line"
    done
fi

### 3. Suspicious script contents
echo "[*] Checking for suspicious script contents..."
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    suspicious_scripts=$(grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null)
    if [ -n "$suspicious_scripts" ]; then
        echo "$suspicious_scripts" | while read -r match; do
            filepath=$(echo "$match" | cut -d: -f1)
            echo "[Suspicious Script] $filepath"
        done
    fi
done

### 4. Suspicious startup entries
echo "[*] Checking for suspicious startup entries..."
startup_entries=$(find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart 2>/dev/null)
if [ -n "$startup_entries" ]; then
    echo "$startup_entries" | while read -r startup; do
        if [ -f "$startup" ] && grep -qEi '\b(nc|python|perl|php|ruby|socat)\b' "$startup"; then
            echo "[Startup File] $startup"
        fi
    done
fi

echo "[✓] Scan complete."
