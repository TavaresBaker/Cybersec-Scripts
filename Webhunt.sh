#!/bin/sh

# List of webhook domains to scan for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"
pattern_list=$(echo "$patterns" | tr ' ' '\n')
total=$(echo "$pattern_list" | wc -l)
current=1

echo "🔍 Scanning for webhook URLs..."

echo "$pattern_list" | while read pattern; do
    echo "⏳ Checking pattern $current of $total..."
    find / -type f -print0 2>/dev/null | xargs -0 grep -H "$pattern" 2>/dev/null
    current=$((current + 1))
done

echo "✅ Scan finished."
