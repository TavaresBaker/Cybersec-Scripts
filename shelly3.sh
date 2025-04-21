#!/bin/sh
# Clean ShellHunter v2 - Reverse/Webshell/Rogue Shell Detection

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo "${YELLOW}[*] Starting scan for suspicious shell activity...${NC}"
echo "====================================================="

### 1. Suspicious processes
echo "${YELLOW}[1/4] Checking for suspicious processes...${NC}"
proc_hits=0
while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
    if [ -n "$exe_path" ]; then
        echo "${RED}$exe_path${NC}"  # Display only the executable path
        proc_hits=1
    fi
done <<EOF
$(ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep)
EOF
[ "$proc_hits" -eq 0 ] && echo "${GREEN}[OK] No suspicious processes found.${NC}"
echo ""

### 2. Suspicious listening ports
echo "${YELLOW}[2/4] Checking for suspicious listening ports...${NC}"
port_hits=0
while read -r line; do
    echo "${RED}$line${NC}"  # Display the line directly from netstat (which includes the port and process info)
    port_hits=1
done <<EOF
$(netstat -tunlp 2>/dev/null | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)')
EOF
[ "$port_hits" -eq 0 ] && echo "${GREEN}[OK] No suspicious ports found.${NC}"
echo ""

### 3. Suspicious script contents
echo "${YELLOW}[3/4] Checking for suspicious script contents...${NC}"
script_hits=0
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    while read -r match; do
        filepath=$(echo "$match" | cut -d: -f1)
        echo "${RED}$filepath${NC}"  # Only display the file path
        script_hits=1
    done <<EOF
$(grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null)
EOF
done
[ "$script_hits" -eq 0 ] && echo "${GREEN}[OK] No suspicious script contents found.${NC}"
echo ""

### 4. Suspicious startup entries
echo "${YELLOW}[4/4] Checking for suspicious startup entries...${NC}"
startup_hits=0
startup_dirs="/etc/rc.d /usr/local/etc/rc.d ~/.config/autostart /etc/init.d /etc/systemd/system"
for path in $startup_dirs; do
    if [ -d "$path" ]; then
        find "$path" -type f 2>/dev/null | while read -r startup; do
            if grep -qEi '\b(nc|python|perl|php|ruby|socat|bash|sh)\b' "$startup"; then
                echo "${RED}$startup${NC}"  # Only display the startup file path
                startup_hits=1
            fi
        done
    fi
done
[ "$startup_hits" -eq 0 ] && echo "${GREEN}[OK] No suspicious startup entries found.${NC}"
echo ""

echo "${GREEN}[✓] Scan complete.${NC}"
