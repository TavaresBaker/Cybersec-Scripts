#!/bin/bash

# Define patterns
patterns=(
    'https:\/\/discord[a-z]*\.com\/api\/webhooks\/[^[:space:]\"]\+'
    'https:\/\/hooks\.slack\.com\/services\/[^[:space:]\"]\+'
    '\.pf\b'
    '\bwebhook\b'
    '\bhookurl\b'
    '\bwebhook_path\b'
)

# Start time
start_time=$(date +%s)

# Collect all files (excluding binaries)
mapfile -t files < <(find . -type f ! -name "*.png" ! -name "*.jpg" ! -name "*.gif" ! -name "*.jpeg" ! -name "*.webp" ! -name "*.exe" ! -name "*.bin" ! -name "*.so" ! -name "*.dll")

total_patterns=${#patterns[@]}
results=()

# Function to show timer
show_progress() {
    local count=$1
    local now=$(date +%s)
    local elapsed=$((now - start_time))
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))
    printf "\r%d out of %d patterns checked | Time: %02d:%02d" "$count" "$total_patterns" "$mins" "$secs"
}

# Search logic
for i in "${!patterns[@]}"; do
    pattern="${patterns[$i]}"
    for file in "${files[@]}"; do
        if [[ -r "$file" ]]; then
            matches=$(grep -niE "$pattern" "$file" 2>/dev/null)
            if [[ -n "$matches" ]]; then
                while IFS= read -r line; do
                    results+=("$file:$line")
                done <<< "$matches"
            fi
        fi
    done
    show_progress $((i + 1))
done

# Newline before output
echo

# Print only unique results
printf "%s\n" "${results[@]}" | sort -u
