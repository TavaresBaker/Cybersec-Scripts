#!/bin/sh

# Step 0: Detect pfSense version
VERSION_RAW=$(cat /etc/version | cut -d'-' -f1)
BRANCH="RELENG_$(echo "$VERSION_RAW" | tr '.' '_')"

echo "[*] Detected pfSense version: $VERSION_RAW"
echo "[*] Using GitHub branch: $BRANCH"

GITHUB_PFSENSE="https://raw.githubusercontent.com/pfsense/pfsense"
GITHUB_FREEBSD="https://raw.githubusercontent.com/freebsd/freebsd-src/releng/14.0"

FAILED_FILES=""

# Step 1: Go to root's home directory
cd /root || exit 1

# Step 2: Create backup folder
mkdir -p backups_php

# Step 3: Copy /usr/local/www into backup
cp -a /usr/local/www backups_php/

echo "[+] Backup complete at /root/backups_php/www"

# Step 4: Go to /usr/local
cd /usr/local || exit 1

# Step 5: Download fresh www directory from GitHub
fetch "https://codeload.github.com/pfsense/pfsense/zip/refs/heads/${BRANCH}" -o pfsense.zip

# Step 6: Unzip and replace www
unzip -oq pfsense.zip
rm -rf www
cp -a "pfsense-${BRANCH}/src/usr/local/www" .

# Step 7: Cleanup
rm -rf pfsense.zip "pfsense-${BRANCH}"

echo "[✔] /usr/local/www has been replaced from GitHub."

# Step 8: Restore rc.initial reliably
echo "[*] Restoring /etc/rc.initial..."

RC_LOCAL="/etc/rc.initial"
TMP_FILE="/tmp/rc.initial"
RC_BRANCHES="$BRANCH master main"

for BR in $RC_BRANCHES; do
  RC_URL="${GITHUB_PFSENSE}/${BR}/src/etc/rc.initial"
  echo "[~] Trying: $RC_URL"
  curl -fsSL "$RC_URL" -o "$TMP_FILE" && break
done

if [ -f "$TMP_FILE" ]; then
  [ -L "$RC_LOCAL" ] && rm -f "$RC_LOCAL"  # Remove symlink if needed
  cp "$TMP_FILE" "$RC_LOCAL"
  chmod +x "$RC_LOCAL"
  echo "[✔] /etc/rc.initial restored."
else
  echo "[!] Failed to restore /etc/rc.initial"
  FAILED_FILES="${FAILED_FILES}\n/etc/rc.initial"
fi

# Step 9: Restore rc.d scripts
echo "[*] Attempting to restore /usr/local/etc/rc.d/* scripts..."

mkdir -p /root/backups_php/rc.d
cp -a /usr/local/etc/rc.d /root/backups_php/rc.d/

fetch https://codeload.github.com/pfsense/FreeBSD-ports/zip/refs/heads/devel -o ports.zip
unzip -oq ports.zip

if [ -d "FreeBSD-ports-devel" ]; then
  rm -rf /usr/local/etc/rc.d/*
  find FreeBSD-ports-devel -type f -name "*.in" -exec cp {} /usr/local/etc/rc.d/ \;
  echo "[✔] rc.d scripts restored from FreeBSD-ports."
else
  echo "[!] Failed to restore rc.d scripts"
  FAILED_FILES="${FAILED_FILES}\n/usr/local/etc/rc.d/*"
fi

# Cleanup
rm -rf ports.zip FreeBSD-ports-devel "$TMP_FILE"

# Step 10: Final result
if [ -n "$FAILED_FILES" ]; then
  echo "[!] The following files failed to update:"
  echo -e "$FAILED_FILES"
else
  echo "[✔] All files restored successfully."
fi
