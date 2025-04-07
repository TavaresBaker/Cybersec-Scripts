#!/bin/sh

# List of webhook domains to scan for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

echo "🔍 Scanning for webhook URLs..."

for pattern in $patterns; do
    find / -type f -print0 2>/dev/null | xargs -0 grep -H "$pattern" 2>/dev/null
done

echo "✅ Scan finished."
