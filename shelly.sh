#!/bin/sh
# Clean ShellHunter v2 - Reverse/Webshell/Rogue Shell Detection

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}[*] Starting scan for suspicious shell activity...${NC}"
echo "====================================================="

### 1. Suspicious processes
echo -e "${YELLOW}[1/4] Checking for suspicious processes...${NC}"
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
    [ -n "$exe_path" ] && echo -e "${RED}[Weird Process] PID: $pid - $exe_path${NC}"
done
echo ""

### 2. Suspicious listening ports
echo -e "${YELLOW}[2/4] Checking for suspicious listening ports...${NC}"
netstat -tunlp 2>/dev/null | grep -E '(:4444|:1337|:1234|:9001|:2222|:8080)' | while read -r line; do
    port=$(echo "$line" | awk '{print $4}')
    proc=$(echo "$line" | awk '{print $7}')
    echo -e "${RED}[Reverse Shell Port] $port - $proc${NC}"
done
echo ""

### 3. Suspicious script contents
echo -e "${YELLOW}[3/4] Checking for suspicious script contents...${NC}"
for dir in /home /tmp /var/tmp; do
    [ -d "$dir" ] || continue
    grep -r --include="*.sh" -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$dir" 2>/dev/null | while read -r match; do
        filepath=$(echo "$match" | cut -d: -f1)
        echo -e "${RED}[Suspicious Script] $filepath${NC}"
    done
done
echo ""

### 4. Suspicious startup entries
echo -e "${YELLOW}[4/4] Checking for suspicious startup entries...${NC}"
startup_dirs="/etc/rc.d /usr/local/etc/rc.d $HOME/.config/autostart"
for path in $startup_dirs; do
    find $path -type f 2>/dev/null | while read -r startup; do
        if grep -qEi '\b(nc|python|perl|php|ruby|socat)\b' "$startup"; then
            echo -e "${RED}[Startup File] $startup${NC}"
        fi
    done
done
echo ""

echo -e "${GREEN}[✓] Scan complete.${NC}"
