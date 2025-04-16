#!/bin/sh

SEARCH_DIR="/"

# Escaped regex for Discord, Slack, and general webhook-like URLs
WEBHOOK_REGEX="https:\/\/\(discord\(app\)\{0,1\}\.com\/api\/webhooks\|hooks\.slack\.com\/services\|.*/webhook/.*\)"

TOTAL_FILES=$(find "$SEARCH_DIR" -type f | wc -l)
[ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1

START_TIME=$(date +%s)
SCANNED=0

# Temp file to store matches in-memory
MATCHES_FILE="/tmp/webhook_matches.$$"
> "$MATCHES_FILE"

trap 'echo "\nCancelled."; rm -f "$MATCHES_FILE"; exit 1' INT

find "$SEARCH_DIR" -type f | while read -r file; do
  SCANNED=$((SCANNED + 1))

  # Search and collect results with file and line number
  grep -En "$WEBHOOK_REGEX" "$file" 2>/dev/null >> "$MATCHES_FILE"

  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))

  PERCENT=$((SCANNED * 100 / TOTAL_FILES))

  printf "\rChecked: %d/%d files | %d%% | Elapsed: %02d:%02d" "$SCANNED" "$TOTAL_FILES" "$PERCENT" "$MINS" "$SECS"
done

echo "\n\n🎯 Matches Found:\n"

if [ -s "$MATCHES_FILE" ]; then
  cat "$MATCHES_FILE"
else
  echo "No webhook URLs found."
fi

rm -f "$MATCHES_FILE"
