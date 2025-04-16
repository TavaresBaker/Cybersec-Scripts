#!/bin/sh

SEARCH_DIR="/"

WEBHOOK_REGEX="https:\/\/\(discord\(app\)\{0,1\}\.com\/api\/webhooks\|hooks\.slack\.com\/services\|.*/webhook/.*\)"

TOTAL_FILES=$(find "$SEARCH_DIR" -type f | wc -l)
[ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1

START_TIME=$(date +%s)
SCANNED=0

trap 'echo "\nCancelled."; exit 1' INT

find "$SEARCH_DIR" -type f | while read -r file; do
  SCANNED=$((SCANNED + 1))

  # Check for matches and print them if found
  MATCH=$(grep -E "$WEBHOOK_REGEX" "$file" 2>/dev/null)
  if [ -n "$MATCH" ]; then
    echo "\n🔍 Match found in: $file"
    echo "$MATCH"
  fi

  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))

  PERCENT=$((SCANNED * 100 / TOTAL_FILES))

  printf "\rChecked: %d/%d files | %d%% | Elapsed: %02d:%02d" "$SCANNED" "$TOTAL_FILES" "$PERCENT" "$MINS" "$SECS"
done


