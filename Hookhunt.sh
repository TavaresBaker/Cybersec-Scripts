#!/bin/sh

# === Configuration ===
# Known webhook domains (expand as needed)
WEBHOOK_PATTERNS="hooks.slack.com\|discord.com/api/webhooks\|discordapp.com/api/webhooks\|outlook.office.com/webhook\|mattermost.com/hooks\|webhook.site\|github.com/.*/hooks"

# General URL pattern (catch-all)
URL_PATTERN="http[s]?://[a-zA-Z0-9./?=_:-]*"

# Directories to scan
SEARCH_DIRS="/cf /etc /usr/local /root /tmp /var"

# Output log
LOG_FILE="/root/webhook_url_scan_$(date +%Y%m%d_%H%M%S).log"

echo "🔍 Starting deep scan for webhooks and URLs..."
echo "Log file: $LOG_FILE"

# Start fresh
> "$LOG_FILE"

for DIR in $SEARCH_DIRS; do
  if [ -d "$DIR" ]; then
    echo "➡️ Scanning directory: $DIR"
    find "$DIR" -type f | while read -r file; do
      # Scan for webhooks
      grep -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null >> "$LOG_FILE"
      # Scan for any URL
      grep -oEi "$URL_PATTERN" "$file" 2>/dev/null >> "$LOG_FILE"
    done
  fi
done

echo "✅ Scan complete. Results saved to $LOG_FILE"
