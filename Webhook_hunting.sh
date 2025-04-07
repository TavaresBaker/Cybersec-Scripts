#!/bin/sh

# Webhook patterns to search for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

# Results file
results_file="/tmp/webhook_hits.txt"
: > "$results_file"  # Empty it

total_patterns=$(echo "$patterns" | wc -w)
current_pattern=0

# Function to show a live timer
start_timer() {
    seconds=0
    while true; do
        printf "\r⏱️  Pattern %d/%d — Elapsed: %02d sec" "$current_pattern" "$total_patterns" "$seconds"
        sleep 1
        seconds=$((seconds + 1))
    done
}

echo "🔍 Starting webhook scan..."

# Loop through each pattern
for pattern in $patterns; do
    current_pattern=$((current_pattern + 1))

    # Start timer in background
    start_timer &
    timer_pid=$!

    # Search and store results
    find / -type f 2>/dev/null | while read file; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            grep -H "$pattern" "$file" 2>/dev/null >> "$results_file"
        fi
    done

    # Stop timer
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null

    # Clear timer line
    printf "\r✅ Pattern %d/%d complete.                             \n" "$current_pattern" "$total_patterns"
done

# Final Summary
hit_count=$(wc -l < "$results_file")

echo
echo "✅ Full scan complete."
echo "🔢 Total hits: $hit_count"

if [ "$hit_count" -gt 0 ]; then
    echo
    echo "📁 Files containing webhooks:"
    cut -d: -f1 "$results_file" | sort | uniq

    echo
    echo "📄 Matched lines:"
    cat "$results_file"
else
    echo "👍 No webhook URLs found."
fi
