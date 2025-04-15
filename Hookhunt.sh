#!/bin/sh

# === Config ===
WEBHOOK_PATTERNS="hooks.slack.com|discord.com/api/webhooks|discordapp.com/api/webhooks|outlook.office.com/webhook|mattermost.com/hooks|webhook.site|github.com/.*/hooks"
URL_PATTERN='http[s]?://[^"'"'"' <>]*'
SEARCH_DIRS="/cf /etc /usr/local /root /var"

# Only scan these text-based extensions
EXTENSIONS="xml|php|conf|sh|inc|txt|log"

# Timestamped log file
LOG_FILE="/root/webhook_url_scan_$(date +%Y%m%d_%H%M%S).log"
> "$LOG_FILE"

echo "🔍 Starting optimized scan — logging to $LOG_FILE"

# Webhook pattern scan
find $SEARCH_DIRS \
  -type f \
  -iregex ".*\.(${EXTENSIONS})" \
  ! -size +5M \
  2>/dev/null | \
xargs grep -iE "$WEBHOOK_PATTERNS" 2>/dev/null >> "$LOG_FILE"

# General URL scan
find $SEARCH_DIRS \
  -type f \
  -iregex ".*\.(${EXTENSIONS})" \
  ! -size +5M \
  2>/dev/null | \
xargs grep -oEi "$URL_PATTERN" 2>/dev/null >> "$LOG_FILE"

# Final message
echo "✅ Scan complete. Results saved to $LOG_FILE"

# Clear the screen
sleep 2
clear

# Open the log file
ee "$LOG_FILE"
