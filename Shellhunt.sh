#!/bin/sh
# Clean ShellHunter - Reverse Shell Detection

echo "[*] Starting scan for suspicious shell activity..."

# Initialize finding variables
processes_output=""
ports_output=""
scripts_output=""
startup_entries_output=""

# 1. Suspicious processes
echo "[*] Checking for suspicious processes..."
suspicious_cmds='nc|netcat|bash -i|python.*socket|perl.*socket|ruby.*socket|socat'
processes=$(ps aux)

echo "$processes" | grep -Ei "$suspicious_cmds" | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/file" 2>/dev/null)
    if [ -n "$exe_path" ]; then
        processes_output="$processes_output\n[Weird Process] $exe_path"
    fi
done

# 2. Suspicious listening ports
echo "[*] Checking for suspicious listening ports..."
ports=$(netstat -an | grep -E 'LISTEN' | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)')
if [ -n "$ports" ]; then
    while read -r line; do
        ports_output="$ports_output\n[Reverse Shell Port] $line"
    done <<EOF
$ports
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
            scripts_output="$scripts_output\n[Suspicious Script] $filepath"
        done <<EOF
$matches
EOF
    fi
done

# 4. Suspicious startup entries
echo "[*] Checking for suspicious startup entries..."
startup_files=$(find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart 2>/dev/null)
if [ -n "$startup_files" ]; then
    echo "$startup_files" | while read -r file; do
        if [ -f "$file" ] && grep -qEi '\b(nc|python|perl|ruby|socat)\b' "$file"; then
            startup_entries_output="$startup_entries_output\n[Startup File] $file"
        fi
    done
fi

# Final output
echo "[✓] Scan complete."

[ -n "$processes_output" ] && echo -e "$processes_output"
[ -n "$ports_output" ] && echo -e "$ports_output"
[ -n "$scripts_output" ] && echo -e "$scripts_output"
[ -n "$startup_entries_output" ] && echo -e "$startup_entries_output"
