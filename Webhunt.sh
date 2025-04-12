#!/bin/sh

# Output file for results
OUTPUT="/root/discord_webhooks_found.txt"
> "$OUTPUT"

echo "Scanning system for Discord webhooks..."
echo "Results will be saved to: $OUTPUT"
echo "----------" > "$OUTPUT"

# Define the pattern for a Discord webhook URL
WEBHOOK_PATTERN="discord\.com/api/webhooks"

# Search key directories
for DIR in /etc /root /usr /var /tmp /home /conf; do
    echo "Scanning $DIR..."
    find "$DIR" -type f 2>/dev/null | while read FILE; do
        if grep -qE "$WEBHOOK_PATTERN" "$FILE" 2>/dev/null; then
            echo "Found potential webhook in: $FILE" | tee -a "$OUTPUT"
            grep -E "$WEBHOOK_PATTERN" "$FILE" | tee -a "$OUTPUT"
            echo "-----------------------------" >> "$OUTPUT"
        fi
    done
done

echo "Scan complete."
echo "Review the file at $OUTPUT"
