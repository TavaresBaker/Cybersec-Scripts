#!/bin/bash

# List of common webhook URL patterns
patterns=(
  "hooks.slack.com"
  "discord.com/api/webhooks"
  "outlook.office.com/webhook"
  "mattermost.com/hooks"
  "webhook.site"
  "zapier.com/hooks"
  "ifttt.com/trigger"
  "api.github.com/repos/.*/hooks"
)

echo "🔍 Scanning for known webhook URLs..."
echo

# Search recursively in current directory
for pattern in "${patterns[@]}"; do
    echo "Looking for: $pattern"
    grep -R --color=always -i "$pattern" . || echo "❌ None found for $pattern"
    echo "--------------------------------------"
done

echo "✅ Scan complete."
