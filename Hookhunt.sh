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
> "$LOG_FILE"

echo "🔎 Smart scan started... Logging to $LOG_FILE"

# === Scan Relevant Files ===
find $SEARCH_DIRS \
  -type f \
  -iregex ".*\.(${EXTENSIONS})" \
  ! -size +5M 2>/dev/null | while IFS= read -r file; do

    # Sanity check
    [ ! -f "$file" ] && continue

    # Check for webhook matches
    MATCHES=$(grep -a -iE "$WEBHOOK_PATTERNS" "$file" 2>/dev/null)
    if [ -n "$MATCHES" ]; then
        echo "[WEBHOOK] $file" >> "$LOG_FILE"
        echo "$MATCHES" >> "$LOG_FILE"
    fi

    # Check for other URLs not in the safe list
    URLS=$(grep -a -oEi "$URL_PATTERN" "$file" 2>/dev/null | grep -aviE "$SAFE_DOMAINS")
    if [ -n "$URLS" ]; then
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
echo "📄 Suspicious findings:"
echo "---------------------------------------------"
cat "$LOG_FILE"
echo "---------------------------------------------"
