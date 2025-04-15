#!/bin/sh

# === Setup ===
WEBHOOK_PATTERNS="hooks.slack.com|discord(app)?.com/api/webhooks|outlook.office.com/webhook|mattermost.com/hooks|webhook.site|github.com/.*/hooks"
URL_PATTERN='http[s]?://[^\"'"'"' <>]*'
SEARCH_DIRS="/cf /etc /usr/local /root /var"
LOG_FILE="/root/webhook_scan.log"

# === Start Timer ===
START_TIME=$(date +%s)
> "$LOG_FILE"

echo "🔍 Deep scan started... Logging to $LOG_FILE"

# === Scan ===
find $SEARCH_DIRS -type f ! -size +10M 2>/dev/null | while read -r file; do
  FILETYPE=$(file -b --mime-type "$file")
  case "$FILETYPE" in
    text/*|application/xml|application/json)
      MATCHES=$(grep -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null)
      [ -n "$MATCHES" ] && echo "[WEBHOOK] $file" >> "$LOG_FILE" && echo "$MATCHES" >> "$LOG_FILE"

      URLS=$(grep -oEi "$URL_PATTERN" "$file" 2>/dev/null)
      [ -n "$URLS" ] && echo "[URLS] $file" >> "$LOG_FILE" && echo "$URLS" >> "$LOG_FILE"
      ;;
    *) ;; # Skip non-text
  esac
done

# === End Timer ===
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# === Output Results ===
sleep 1
clear
echo "✅ Scan completed in $DURATION seconds."
echo "📄 Results from $LOG_FILE:"
echo "---------------------------------------------"
cat "$LOG_FILE"
echo "---------------------------------------------"
