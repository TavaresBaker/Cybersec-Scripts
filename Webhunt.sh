#!/bin/sh

# List of webhook domains to scan for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

# Convert patterns into an array
pattern_list=$(echo "$patterns" | tr ' ' '\n')
total=$(echo "$pattern_list" | wc -l)
current=1

# Temporary file to store results
results_file="/tmp/webhook_hits.txt"
: > "$results_file"  # Empty the file before starting

echo "🔍 Scanning for webhook URLs..."

echo "$pattern_list" | while read pattern; do
    echo "⏳ Checking pattern $current of $total..."
    find / -type f -print0 2>/dev/null | xargs -0 grep -H "$pattern" 2>/dev/null >> "$results_file"
    current=$((current + 1))
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
    echo
    echo "📄 Matching lines:"
    cat "$results_file"
fi
