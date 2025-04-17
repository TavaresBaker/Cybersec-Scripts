#!/bin/sh

echo "Searching for SSH keys on pfSense (content-only scan)..."

# Directories to search
SEARCH_DIRS="/root /home /etc /usr /var /cf /tmp"

# File size limit (to avoid huge binary files)
MAXSIZE=1048576  # 1 MB

# Temporary file to store results
RESULTS="/tmp/ssh_key_search_results.txt"
> "$RESULTS"

# Function to scan file content for SSH key material
scan_file() {
    FILE="$1"
    if [ -f "$FILE" ]; then
        SIZE=$(stat -f%z "$FILE" 2>/dev/null)
        if [ "$SIZE" -le "$MAXSIZE" ]; then
            if grep -qE "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY" "$FILE" || \
               grep -qE "ssh-(rsa|dss|ed25519|ecdsa)" "$FILE"; then
                echo "$FILE" >> "$RESULTS"
            fi
        fi
    fi
}

export -f scan_file
export MAXSIZE
export RESULTS

# Scan all regular files
find $SEARCH_DIRS -type f -exec sh -c 'scan_file "$0"' {} \;

# Clear the screen before showing final results
clear
echo "=== SSH Key Scan Results ==="

if [ -s "$RESULTS" ]; then
    cat "$RESULTS"
else
    echo "No SSH keys found in file contents."
fi

# Optional: delete the results file
# rm "$RESULTS"
