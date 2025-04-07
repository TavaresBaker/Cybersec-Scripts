#!/bin/sh

# Webhook patterns to search for (including 'url' and other concrete patterns)
patterns="hooks.slack.com discord.com/api/webhooks outlook.office.com/webhook webhook.site zapier.com/hooks ifttt.com/trigger url"

# Temp results file
results_file="/tmp/webhook_hits.txt"
: > "$results_file"

# Convert patterns into a format for grep (-e option for multiple patterns)
grep_patterns=""
for pattern in $patterns; do
    grep_patterns+="-e $pattern "
done

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

# Run `find` once and then pass the result to `grep` with multiple patterns
find / -type f 2>/dev/null | while read file; do
    # Start the timer only for the first pattern
    if [ "$current_pattern" -eq 0 ]; then
        start_timer &
        timer_pid=$!
    fi

    # Search for multiple patterns in the file and output the result with line numbers
    grep -Hn $grep_patterns "$file" 2>/dev/null | while read match; do
        echo "$match" >> "$results_file"
    done
done

# Kill the timer process
kill "$timer_pid" 2>/dev/null
wait "$timer_pid" 2>/dev/null
printf "\r                                              \r"

# Final deduplicated output
hits=$(sort -u "$results_file")

if [ -n "$hits" ]; then
    echo "✅ Found the following files with webhook URLs:"
    echo "$hits"
else
    echo "✅ No webhook URLs found."
fi
