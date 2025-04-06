#!/bin/sh

# Step 1: Go to root's home directory
cd /root || exit 1

# Step 2: Create backup folder
mkdir -p backups_php

# Step 3: Copy /usr/local/www into backup
cp -a /usr/local/www backups_php/

echo "[+] Backup complete at /root/backups_php/www"

# Step 4: Go to /usr/local
cd /usr/local || exit 1

# Step 5: Download fresh www directory from GitHub (RELENG_2_7_0)
fetch https://codeload.github.com/pfsense/pfsense/zip/refs/heads/RELENG_2_7_0 -o pfsense.zip

# Step 6: Unzip and replace www
unzip -oq pfsense.zip
rm -rf www
cp -a pfsense-RELENG_2_7_0/src/usr/local/www .

# Step 7: Cleanup
rm -rf pfsense.zip pfsense-RELENG_2_7_0

echo "[✔] /usr/local/www has been replaced from GitHub."
