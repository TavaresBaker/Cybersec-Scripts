#!/bin/sh

# Basic list of webhook domains to search for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

echo "Scanning for webhook URLs..."

for pattern in $patterns; do
    echo "Looking for $pattern..."
    find / -type f -exec grep "$pattern" {} \; 2>/dev/null
    echo "------------------------------"
done

echo "Scan finished."
