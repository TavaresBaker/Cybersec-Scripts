#!/bin/sh

# List of webhook domains to scan for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

# Temporary file to store results
results_file="/tmp/webhook_hits.txt"
: > "$results_file"  # Empty the file before starting

echo "🔍 Scanning for webhook URLs..."

hit_count=0

for pattern in $patterns; do
    echo "🔎 Looking for: $pattern"
    find / -type f 2>/dev/null | while read file; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            grep -H "$pattern" "$file" 2>/dev/null | tee -a "$results_file"
        fi
    done
    echo "--------------------------------------"
done

# Count hits
hit_count=$(wc -l < "$results_file")

# Print summary
echo
echo "✅ Scan complete."
echo "🔢 Total hits: $hit_count"

if [ "$hit_count" -gt 0 ]; then
    echo
    echo "📁 Files with matches:"
    cut -d: -f1 "$results_file" | sort | uniq
fi
