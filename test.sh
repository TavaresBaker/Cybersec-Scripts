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

# =====================
# Additional Restoration
# =====================
echo "[*] Restoring critical system files..."

GITHUB_BASE="https://raw.githubusercontent.com/pfsense/pfsense/RELENG_2_7_0"
FAILED_FILES=""

# Declare file map: local_path:github_relative_path
FILES_TO_RESTORE="
/etc/passwd:src/etc/passwd
/etc/master.passwd:src/etc/master.passwd
/etc/crontab:src/etc/crontab
/etc/rc.initial:src/etc/rc.initial
/etc/ssh/sshd_config:src/etc/ssh/sshd_config
"

for item in $FILES_TO_RESTORE; do
  LOCAL_FILE=$(echo "$item" | cut -d: -f1)
  GITHUB_PATH=$(echo "$item" | cut -d: -f2)
  TMP_FILE="/tmp/$(basename "$LOCAL_FILE")"

  echo "[~] Restoring $LOCAL_FILE"
  curl -fsSL "${GITHUB_BASE}/${GITHUB_PATH}" -o "$TMP_FILE"

  if [ $? -eq 0 ]; then
    cp "$TMP_FILE" "$LOCAL_FILE"
  else
    echo "[!] Failed to restore $LOCAL_FILE"
    FAILED_FILES="${FAILED_FILES}\n$LOCAL_FILE"
  fi
done

# Restore /usr/local/etc/rc.d from GitHub if possible
mkdir -p /root/backups_php/rc.d /root/backups_php/pkg
cp -a /usr/local/etc/rc.d /root/backups_php/rc.d/
cp -a /usr/local/pkg /root/backups_php/pkg/

echo "[*] Backups of rc.d and pkg stored."

# These are directories, so we’ll use tarballs from GitHub
# (pfSense doesn't always have raw files for these)
echo "[~] Downloading rc.d and pkg script directories..."

fetch https://github.com/pfsense/pfsense/archive/refs/heads/RELENG_2_7_0.zip -o fullsrc.zip
unzip -oq fullsrc.zip

if [ -d "pfsense-RELENG_2_7_0/src/usr/local/etc/rc.d" ]; then
  rm -rf /usr/local/etc/rc.d/*
  cp -a pfsense-RELENG_2_7_0/src/usr/local/etc/rc.d/* /usr/local/etc/rc.d/
else
  echo "[!] Failed to restore /usr/local/etc/rc.d"
  FAILED_FILES="${FAILED_FILES}\n/usr/local/etc/rc.d/*"
fi

if [ -d "pfsense-RELENG_2_7_0/src/usr/local/pkg" ]; then
  rm -rf /usr/local/pkg/*
  cp -a pfsense-RELENG_2_7_0/src/usr/local/pkg/* /usr/local/pkg/
else
  echo "[!] Failed to restore /usr/local/pkg"
  FAILED_FILES="${FAILED_FILES}\n/usr/local/pkg/*"
fi

# Clean up
rm -rf fullsrc.zip pfsense-RELENG_2_7_0

# Report any failures
if [ -n "$FAILED_FILES" ]; then
  echo "[!] The following files failed to update:"
  echo -e "$FAILED_FILES"
else
  echo "[✔] All critical files restored successfully."
fi
