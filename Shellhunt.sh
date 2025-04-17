old

#!/bin/sh
# Clean ShellHunter - Reverse Shell Detection

echo "[*] Starting scan for suspicious shell activity..."

### 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
proc_hits=0
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/file" 2>/dev/null)
    if [ -n "$exe_path" ]; then
        echo "[Weird Process] $exe_path"
        proc_hits=1
    fi
done
[ "$proc_hits" -eq 0 ] && echo "[OK] No suspicious processes found."

### 2. Suspicious listening ports
echo "[*] Checking for suspicious listening ports..."
port_hits=0
netstat -an | grep -E 'LISTEN' | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)' | while read -r line; do
    echo "[Reverse Shell Port] $line"
    port_hits=1
done
[ "$port_hits" -eq 0 ] && echo "[OK] No suspicious ports found."

### 3. Suspicious script contents
echo "[*] Checking for suspicious script contents..."
script_hits=0
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null | while read -r match; do
        filepath=$(echo "$match" | cut -d: -f1)
        echo "[Suspicious Script] $filepath"
        script_hits=1
    done
done
[ "$script_hits" -eq 0 ] && echo "[OK] No suspicious script contents found."

### 4. Suspicious startup entries
echo "[*] Checking for suspicious startup entries..."
startup_hits=0
find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart 2>/dev/null | while read -r startup; do
    if [ -f "$startup" ] && grep -qEi '\b(nc|python|perl|php|ruby|socat)\b' "$startup"; then
        echo "[Startup File] $startup"
        startup_hits=1
    fi
done
[ "$startup_hits" -eq 0 ] && echo "[OK] No suspicious startup entries found."

echo "[✓] Scan complete."
