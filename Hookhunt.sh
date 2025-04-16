#!/bin/sh

SCAN_DIR="/"
WEBHOOK_REGEX="discord.com/api/webhooks\|discordapp.com/api/webhooks"
CHECKED=0
START=$(date +%s)

# Get a list of all text-readable files (skip binaries)
FILES=$(find "$SCAN_DIR" -type f 2>/dev/null)
TOTAL=$(echo "$FILES" | wc -l)

# Display timer
timer() {
    while :; do
        NOW=$(date +%s)
        ELAPSED=$((NOW - START))
        MINS=$((ELAPSED / 60))
        SECS=$((ELAPSED % 60))
        PERCENT=$((CHECKED * 100 / TOTAL))
        printf "\rTime Elapsed: %02d:%02d | Files Checked: %d/%d | %d%%" "$MINS" "$SECS" "$CHECKED" "$TOTAL" "$PERCENT"
        sleep 1
    done
}

# Start timer in background
timer &
TIMER_PID=$!

# Scan files
echo "$FILES" | while read -r file; do
    # Avoid binaries or system-protected files
    if file "$file" | grep -q "text"; then
        grep -E "$WEBHOOK_REGEX" "$file" >/dev/null 2>&1
        # You can do something with matches here if needed
    fi
    CHECKED=$((CHECKED + 1))
done

# Kill timer and wrap up
kill "$TIMER_PID" 2>/dev/null
echo "\nScan complete."
