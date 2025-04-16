#!/bin/sh

# Directories you care about — adjust as needed
SEARCH_DIR="/usr/local /etc /root /cf/conf /usr/local/www"

# File types to scan (can add/remove extensions)
EXTENSIONS="sh php py js json conf yaml yml ini txt"

# Grep pattern — case-insensitive, any 'webhook' variation
WEBHOOK_REGEX="[Ww][Ee][Bb][Hh][Oo][Oo][Kk][Ss]*"

# Temp match store
MATCHES_FILE="/tmp/webhook_matches.$$"
> "$MATCHES_FILE"

START_TIME=$(date +%s)
SCANNED=0

# Build find expression
FIND_EXPR=""
for ext in $EXTENSIONS; do
  FIND_EXPR="$FIND_EXPR -o -iname '*.$ext'"
done
# Remove leading -o
FIND_EXPR=$(echo "$FIND_EXPR" | sed 's/^-o //')

# Get files to scan
FILES=$(find $SEARCH_DIR \( $FIND_EXPR \))

TOTAL_FILES=$(echo "$FILES" | wc -l)
[ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1

trap 'echo "\nCancelled."; rm -f "$MATCHES_FILE"; exit 1' INT

echo "🔎 Scanning $TOTAL_FILES files for anything 'webhook' related..."

echo "$FILES" | while read -r file; do
  SCANNED=$((SCANNED + 1))

  # Confirm it's text, not binary
  if file "$file" | grep -qi 'text'; then
    grep -in "$WEBHOOK_REGEX" "$file" 2>/dev/null >> "$MATCHES_FILE"
  fi

  # Live status
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))
  PERCENT=$((SCANNED * 100 / TOTAL_FILES))

  printf "\rChecked: %d/%d files | %d%% | Elapsed: %02d:%02d" "$SCANNED" "$TOTAL_FILES" "$PERCENT" "$MINS" "$SECS"
done

# Done
echo "\n\n🎯 Matches Found:\n"
if [ -s "$MATCHES_FILE" ]; then
  cat "$MATCHES_FILE"
else
  echo "No webhook-related content found."
fi

rm -f "$MATCHES_FILE"
