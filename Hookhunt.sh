#!/bin/sh

# === Patterns ===
WEBHOOK_PATTERNS="hooks.slack.com|discord(app)?.com/api/webhooks|outlook.office.com/webhook|mattermost.com/hooks|webhook.site|github.com/.*/hooks"
URL_PATTERN='http[s]?://[^\"'"'"' <>]*'

# === Search Scope ===
SEARCH_DIRS="/cf /etc /usr/local/etc /root"
EXTENSIONS="conf|php|xml|json|sh|inc|txt"

LOG_FILE="/root/webhook_scan.log"
START_TIME=$(date +%s)
> "$LOG_FILE"

echo "🔎 Quick scan started... Logging to $LOG_FILE"

# === Scan Selected File Types Only ===
find $SEARCH_DIRS \
  -type f \
  -iregex ".*\.(${EXTENSIONS})" \
  ! -size +5M 2>/dev/null | while read -r file; do
    MATCHES=$(grep -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null)
    [ -n "$MATCHES" ] && echo "[WEBHOOK] $file" >> "$LOG_FILE" && echo "$MATCHES" >> "$LOG_FILE"

    URLS=$(grep -oEi "$URL_PATTERN" "$file" 2>/dev/null)
    [ -n "$URLS" ] && echo "[URLS] $file" >> "$LOG_FILE" && echo "$URLS" >> "$LOG_FILE"
done

# === Timer + Output ===
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

sleep 1
clear
echo "✅ Scan finished in $DURATION seconds."
echo "📄 Findings:"
echo "---------------------------------------------"
cat "$LOG_FILE"
echo "---------------------------------------------"
