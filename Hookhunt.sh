#!/bin/sh

SCAN_DIR="/"
WEBHOOK_REGEX="discord.com/api/webhooks\|discordapp.com/api/webhooks"
START=$(date +%s)
CHECKED=0

# Get file list
FILELIST=$(mktemp)
find "$SCAN_DIR" -type f 2>/dev/null > "$FILELIST"
TOTAL=$(wc -l < "$FILELIST")

# Display timer
timer() {
    while :; do
        NOW=$(date +%s)
        ELAPSED=$((NOW - START))
        MINS=$((ELAPSED / 60))
        SECS=$((ELAPSED % 60))
        if [ "$TOTAL" -gt 0 ]; then
            PERCENT=$((CHECKED * 100 / TOTAL))
        else
            PERCENT=100
        fi
        printf "\rTime Elapsed: %02d:%02d | Files Checked: %d/%d | %d%%" "$MINS" "$SECS" "$CHECKED" "$TOTAL" "$PERCENT"
        sleep 1
    done
}

# Start timer
timer &
TIMER_PID=$!

# Scan files without subshell
while IFS= read -r file; do
    if file "$file" 2>/dev/null | grep -q "text"; then
        grep -E "$WEBHOOK_REGEX" "$file" >/dev/null 2>&1
    fi
    CHECKED=$((CHECKED + 1))
done < "$FILELIST"

# Cleanup
kill "$TIMER_PID" 2>/dev/null
rm "$FILELIST"
echo "\nScan complete."
