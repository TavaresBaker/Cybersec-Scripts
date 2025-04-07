#!/bin/sh

# Webhook patterns to search for
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger"

# Temp results file
results_file="/tmp/webhook_hits.txt"
: > "$results_file"  # Clear it

total_patterns=$(echo "$patterns" | wc -w)
current_pattern=0

# Function to show live timer
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

    # Start timer
    start_timer &
    timer_pid=$!

    # Search
    find / -type f 2>/dev/null | while read file; do
        grep -H "$pattern" "$file" 2>/dev/null >> "$results_file"
    done

    # Stop timer
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null

    # Clear timer line
    printf "\r                                               \r"
done

# Display results
hit_count=$(wc -l < "$results_file")

if [ "$hit_count" -gt 0 ]; then
    echo "✅ Found $hit_count result(s):"
    cat "$results_file"
else
    echo "✅ No webhook URLs found."
fi
