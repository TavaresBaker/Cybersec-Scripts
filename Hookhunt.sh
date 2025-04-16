#!/bin/sh

# Directories you want to scan
SEARCH_DIR="/usr/local /etc /root /cf/conf /usr/local/www"

# Pattern to catch anything 'webhook'-ish (case-insensitive, greedy)
PATTERN="webhook"

# Temp match file
MATCHES="/tmp/webhook_matches.$$"
> "$MATCHES"

# Get all regular files in given dirs
ALL_FILES=$(find $SEARCH_DIR -type f)
TOTAL=$(echo "$ALL_FILES" | wc -l)
[ "$TOTAL" -eq 0 ] && TOTAL=1

START=$(date +%s)
SCANNED=0

trap 'echo "\nAborted. Cleaning up."; rm -f "$MATCHES"; exit 1' INT

echo "🔍 Scanning $TOTAL files for anything like 'webhook'..."

echo "$ALL_FILES" | while read -r file; do
  SCANNED=$((SCANNED + 1))

  # Only check text files (not binaries)
  if file "$file" | grep -qi 'text'; then
    # Grep and log matches with file + line number
    grep -inE "$PATTERN" "$file" 2>/dev/null | sed "s|^|$file:|" >> "$MATCHES"
  fi

  # Timer + progress
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))
  PERCENT=$((SCANNED * 100 / TOTAL))

  printf "\rChecked: %d/%d files | %d%% | Elapsed: %02d:%02d" "$SCANNED" "$TOTAL" "$PERCENT" "$MINS" "$SECS"
done

# Output results
echo "\n\n🎯 Webhook-related matches found:\n"
if [ -s "$MATCHES" ]; then
  cat "$MATCHES"
else
  echo "No matches found."
fi

rm -f "$MATCHES"
