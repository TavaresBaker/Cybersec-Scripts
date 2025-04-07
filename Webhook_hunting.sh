#!/bin/sh

# Webhook patterns to search for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

# Temp results file
results_file="/tmp/webhook_hits.txt"
: > "$results_file"

total_patterns=$(echo "$patterns" | wc -w)
current_pattern=0

# Timer function
start_timer() {
    seconds=0
    while true; do
        printf "\r⏱️  Pattern %d/%d — Elapsed: %02d sec" "$current_pattern" "$total_patterns" "$seconds"
        sleep 1
        seconds=$((seconds + 1))
    done
}

echo "🔍 Starting webhook scan..."

for pattern in $patterns; do
    current_pattern=$((current_pattern + 1))

    # Start timer
    start_timer &
    timer_pid=$!

    # Search, save only file paths
    find / -type f 2>/dev/null | while read file; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            echo "$file" >> "$results_file"
        fi
    done

    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null
    printf "\r                                              \r"
done

# Final deduplicated output
hits=$(sort -u "$results_file")

if [ -n "$hits" ]; then
    echo "✅ Found the following files with webhook URLs:"
    echo "$hits"
else
    echo "✅ No webhook URLs found."
fi
