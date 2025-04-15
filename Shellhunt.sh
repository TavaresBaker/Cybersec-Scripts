#!/bin/sh
# Clean ShellHunter - Refined Reverse Shell Detection

echo "[*] Starting scan for suspicious shell activity..."

# Initialize findings
findings=""

# 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
    cmdline=$(tr -d '\0' < /proc/$pid/cmdline 2>/dev/null)

    # Only flag if running from unusual location or suspicious args
    if echo "$exe_path $cmdline" | grep -qE '/tmp|/dev/shm|bash -i|nc -e|socat|socket|/dev/tcp|php .* -r'; then
        findings="$findings\n[Weird Process] PID $pid - $exe_path - $cmdline"
    fi
done

# 2. Suspicious ports
echo "[*] Checking for suspicious listening ports..."
suspicious_ports=$(netstat -an | grep -E 'LISTEN' | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)')
if [ -n "$suspicious_ports" ]; then
    while read -r line; do
        findings="$findings\n[Reverse Shell Port] $line"
    done <<EOF
$suspicious_ports
EOF
fi

# 3. Suspicious script contents
echo "[*] Checking for suspicious script contents..."
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    matches=$(grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null)
    if [ -n "$matches" ]; then
        while read -r match; do
            filepath=$(echo "$match" | cut -d: -f1)
            findings="$findings\n[Suspicious Script] $filepath"
        done <<EOF
$matches
EOF
    fi
done

# 4. Startup entries
echo "[*] Checking for suspicious startup entries..."
startup_files=$(find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart 2>/dev/null)
if [ -n "$startup_files" ]; then
    echo "$startup_files" | while read -r file; do
        if [ -f "$file" ] && grep -qEi '\b(nc|python|perl|ruby|php|socat)\b' "$file"; then
            findings="$findings\n[Startup File] $file"
        fi
    done
fi

# Final output
echo "[✓] Scan complete."
if [ -n "$findings" ]; then
    echo -e "$findings"
else
    echo "[OK] No suspicious activity found."
fi
