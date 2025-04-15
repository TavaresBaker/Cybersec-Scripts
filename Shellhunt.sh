#!/bin/sh
# Clean ShellHunter - Accurate match output for pfSense

echo "[*] Starting scan for suspicious shell activity..."

# Suspicious startup files
echo "[*] Checking suspicious startup entries..."
found_startup=0

find /etc/rc.d /usr/local/etc/rc.d ~/.config/autostart -type f 2>/dev/null | while read -r startup; do
    if grep -qEi '\b(nc|python|perl|php|ruby|socat)\b' "$startup"; then
        echo "[Startup File] $startup"
        found_startup=1
    fi
done

[ "$found_startup" -eq 0 ] && echo "[OK] No suspicious startup entries found."

echo "[✓] Scan complete."
