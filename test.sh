echo "[*] Restoring critical system files..."

GITHUB_PFSENSE="https://raw.githubusercontent.com/pfsense/pfsense/RELENG_2_7_0"
GITHUB_FREEBSD="https://raw.githubusercontent.com/freebsd/freebsd-src/releng/14.0"
FAILED_FILES=""

# Files that are safe to fetch and replace
FILES_TO_RESTORE="
/etc/crontab:${GITHUB_PFSENSE}/src/etc/crontab
/etc/ssh/sshd_config:${GITHUB_FREEBSD}/etc/ssh/sshd_config
"

for item in $FILES_TO_RESTORE; do
  LOCAL_FILE=$(echo "$item" | cut -d: -f1)
  REMOTE_URL=$(echo "$item" | cut -d: -f2)
  TMP_FILE="/tmp/$(basename "$LOCAL_FILE")"

  echo "[~] Restoring $LOCAL_FILE from $REMOTE_URL"
  curl -fsSL "$REMOTE_URL" -o "$TMP_FILE"

  if [ $? -eq 0 ]; then
    cp "$TMP_FILE" "$LOCAL_FILE"
  else
    echo "[!] Failed to restore $LOCAL_FILE"
    FAILED_FILES="${FAILED_FILES}\n$LOCAL_FILE"
  fi
done

# Warn about files we can't restore automatically
echo "[!] Skipping automatic restore for:"
echo " - /etc/passwd"
echo " - /etc/master.passwd"
echo "Please restore these from a trusted backup or a clean pfSense install."

# Restore rc.d from FreeBSD (fallback)
echo "[*] Attempting to restore /usr/local/etc/rc.d/* from FreeBSD ports tree..."

mkdir -p /root/backups_php/rc.d
cp -a /usr/local/etc/rc.d /root/backups_php/rc.d/

fetch https://codeload.github.com/pfsense/FreeBSD-ports/zip/refs/heads/devel -o ports.zip
unzip -oq ports.zip

if [ -d "FreeBSD-ports-devel/security" ]; then
  rm -rf /usr/local/etc/rc.d/*
  find FreeBSD-ports-devel -type f -name "*.in" -exec cp {} /usr/local/etc/rc.d/ \;
  echo "[✔] rc.d scripts restored from FreeBSD-ports."
else
  echo "[!] Failed to restore rc.d scripts"
  FAILED_FILES="${FAILED_FILES}\n/usr/local/etc/rc.d/*"
fi

# Clean up
rm -rf ports.zip FreeBSD-ports-devel

# Report any failures
if [ -n "$FAILED_FILES" ]; then
  echo "[!] The following files failed to update:"
  echo -e "$FAILED_FILES"
else
  echo "[✔] All remaining files restored successfully."
fi
