#!/bin/sh

# === Config ===
WEBHOOK_PATTERNS="hooks.slack.com|discord(app)?.com/api/webhooks|outlook.office.com/webhook|mattermost.com/hooks|webhook.site|github.com/.*/hooks"
URL_PATTERN='http[s]?://[^"'"'"' <>]*'
SEARCH_DIRS="/cf /etc /usr/local /root /var"

LOG_FILE="/root/webhook_url_scan_$(date +%Y%m%d_%H%M%S).log"
> "$LOG_FILE"

echo "🔍 Deep scan started... Logging to $LOG_FILE"

# Full scan of all files, skipping large ones and some binaries
find $SEARCH_DIRS -type f ! -size +10M 2>/dev/null | while read -r file; do
  # Check MIME type to avoid binary garbage
  FILETYPE=$(file -b --mime-type "$file")
  case "$FILETYPE" in
    text/*|application/xml|application/json)
      echo "📄 Scanning: $file" >> "$LOG_FILE"
      grep -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null >> "$LOG_FILE"
      grep -oEi "$URL_PATTERN" "$file" 2>/dev/null >> "$LOG_FILE"
      ;;
    *)
      # Skip binary or non-text content
      ;;
  esac
done

echo "✅ Scan complete. Results saved to $LOG_FILE"

# Clear screen and open results
sleep 2
clear
ee "$LOG_FILE"
