#!/bin/sh

echo "Searching for SSH keys on pfSense..."

# Common key filename patterns
KEY_PATTERNS="id_rsa id_dsa id_ecdsa id_ed25519 authorized_keys known_hosts ssh_config"

# Directories to search
SEARCH_DIRS="/root /home /etc /usr /var /cf /tmp"

# Find private/public key files by name
echo "\n[*] Looking for key files by name..."
for pattern in $KEY_PATTERNS; do
    find $SEARCH_DIRS -type f -name "$pattern" -o -name "$pattern.pub" 2>/dev/null
done

# Find files containing "BEGIN RSA PRIVATE KEY", etc.
echo "\n[*] Searching for content matching private/public key patterns..."
grep -rslE "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY" $SEARCH_DIRS 2>/dev/null
grep -rslE "ssh-(rsa|dss|ed25519|ecdsa)" $SEARCH_DIRS 2>/dev/null

# Find hidden files likely to be SSH keys
echo "\n[*] Searching for hidden files that may contain SSH keys..."
find $SEARCH_DIRS -type f -name ".*" -exec grep -lE "ssh-(rsa|dss|ed25519|ecdsa)|BEGIN .* PRIVATE KEY" {} \; 2>/dev/null

# Optional: look for unusual file permissions (e.g., 600)
echo "\n[*] Looking for files with 600 permissions..."
find $SEARCH_DIRS -type f -perm 600 -exec grep -lE "PRIVATE KEY|ssh-" {} \; 2>/dev/null

echo "\n[+] SSH key search complete."
