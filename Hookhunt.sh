#!/bin/sh

# === Patterns ===
WEBHOOK_PATTERNS="hooks.slack.com|discord(app)?\.com/api/webhooks|outlook.office.com/webhook|mattermost.com/hooks|webhook.site|github.com/.*/hooks"
URL_PATTERN='http[s]?://[^\"'"'"' <>]*'

# === Whitelist of Safe URLs ===
SAFE_DOMAINS="pfsense.org|netgate.com|pkg.freebsd.org|freebsd.org|github.com/pfsense|ntp.org|nvd.nist.gov|shields.io|letsencrypt.org"

# === Search Scope ===
SEARCH_DIRS="/cf /etc /usr/local/etc /root"
EXTENSIONS="conf|php|xml|json|sh|inc|txt"

LOG_FILE="/root/webhook_scan.log"
START_TIME=$(date +%s)
TOTAL_FILES=0
TOTAL_WEBHOOK_HITS=0
TOTAL_URL_HITS=0
> "$LOG_FILE"

echo "🔎 Smart scan started... Logging to $LOG_FILE"

# === Scan Relevant Files ===
find $SEARCH_DIRS \
  -type f \
  -iregex ".*\.(${EXTENSIONS})" \
  ! -size +5M 2>/dev/null | while IFS= read -r file; do

    TOTAL_FILES=$((TOTAL_FILES + 1))
    echo "Scanning: $file" | tee -a "$LOG_FILE"

    [ ! -f "$file" ] && echo "⚠️ Skipped (not a file): $file" >> "$LOG_FILE" && continue

    # Check for webhook matches
    MATCHES=$(grep -a -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null)
    if [ -n "$MATCHES" ]; then
        TOTAL_WEBHOOK_HITS=$((TOTAL_WEBHOOK_HITS + 1))
        echo "[WEBHOOK] $file" >> "$LOG_FILE"
        echo "$MATCHES" >> "$LOG_FILE"
    fi

    # Check for non-whitelisted URLs
    URLS=$(grep -a -oEi "$URL_PATTERN" "$file" 2>/dev/null | grep -aviE "$SAFE_DOMAINS")
    if [ -n "$URLS" ]; then
        TOTAL_URL_HITS=$((TOTAL_URL_HITS + 1))
        echo "[URLS] $file" >> "$LOG_FILE"
        echo "$URLS" >> "$LOG_FILE"
    fi
done

# === Timer + Output ===
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

sleep 1
clear
echo "✅ Scan finished in $DURATION seconds."
echo "🔍 Scanned $TOTAL_FILES files."
echo "🧷 Webhook matches: $TOTAL_WEBHOOK_HITS"
echo "🌐 Suspicious URLs: $TOTAL_URL_HITS"
echo "📄 Log file: $LOG_FILE"
echo "---------------------------------------------"
cat "$LOG_FILE"
echo "---------------------------------------------"
