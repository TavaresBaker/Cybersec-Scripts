#!/bin/sh

# Directory to search — change this to narrow scope if needed
SEARCH_DIR="/"

# Regex pattern to detect webhook URLs (Discord, Slack, etc.)
WEBHOOK_REGEX="https:\/\/\(discord\(app\)\\{0,1\}\.com\/api\/webhooks\|hooks\.slack\.com\/services\|.*/webhook/.*\)"

# Get total number of files (avoid divide-by-zero)
TOTAL_FILES=$(find "$SEARCH_DIR" -type f | wc -l)
[ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1

START_TIME=$(date +%s)
SCANNED=0

# Catch Ctrl+C
trap 'echo "\nCancelled."; exit 1' INT

# Scan files
find "$SEARCH_DIR" -type f | while read -r file; do
  SCANNED=$((SCANNED + 1))
  
  # Grep for webhook pattern, but don't print
  grep -E "$WEBHOOK_REGEX" "$file" >/dev/null 2>&1

  # Timer
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))

  # Progress %
  PERCENT=$((SCANNED * 100 / TOTAL_FILES))

  # Display dynamic status
  printf "\rChecked: %d/%d files | %d%% | Elapsed: %02d:%02d" "$SCANNED" "$TOTAL_FILES" "$PERCENT" "$MINS" "$SECS"
done

echo "\nScan complete. Type 'clear' to clean up the terminal."
