#!/bin/sh

# Detect pfSense version
VERSION_RAW=$(cat /etc/version | cut -d'-' -f1)
BRANCH="RELENG_$(echo "$VERSION_RAW" | tr '.' '_')"

echo "[*] Detected pfSense version: $VERSION_RAW"
echo "[*] Using GitHub branch: $BRANCH"

TMPDIR="/tmp/pfsense_clean_check"
mkdir -p "$TMPDIR"

# Download official source from GitHub
echo "[*] Downloading official pfSense files..."
fetch -o "$TMPDIR/pfsense.zip" "https://codeload.github.com/pfsense/pfsense/zip/refs/heads/${BRANCH}" || exit 1
unzip -q "$TMPDIR/pfsense.zip" -d "$TMPDIR"

# Source directory from GitHub
SRC_DIR="$TMPDIR/pfsense-${BRANCH}/src"

# List of virtual/system dirs to skip
SKIP_DIRS="/dev /proc /sys /tmp /mnt /media /var/run /var/tmp /compat /root/.cache"

# Store non-native and deleted files
NON_NATIVE="/tmp/non_native_files.txt"
DELETED_LOG="/tmp/deleted_files.log"
> "$NON_NATIVE"
> "$DELETED_LOG"

echo "[*] Scanning full filesystem for non-native files..."

find / -type f 2>/dev/null | while read -r LOCAL_FILE; do
  # Skip system dirs
  for SKIP in $SKIP_DIRS; do
    case "$LOCAL_FILE" in
      $SKIP/*) continue 2 ;;
    esac
  done

  REL_PATH="$LOCAL_FILE"
  REF_FILE="$SRC_DIR$REL_PATH"

  if [ ! -f "$REF_FILE" ]; then
    echo "$LOCAL_FILE" >> "$NON_NATIVE"
  fi
done

echo ""
echo "[*] Non-native files found:"
cat "$NON_NATIVE"
echo ""

# Prompt before deleting
echo "[?] Delete all non-native files listed above? (yes/no)"
read -r CONFIRM
if [ "$CONFIRM" = "yes" ]; then
  while read -r FILE; do
    if rm -f "$FILE"; then
      echo "[✔] Deleted: $FILE"
      echo "$FILE" >> "$DELETED_LOG"
    else
      echo "[!] Failed to delete: $FILE"
    fi
  done < "$NON_NATIVE"
  echo ""
  echo "[✓] All listed files processed. Deleted files logged in: $DELETED_LOG"
else
  echo "[!] No files were deleted."
fi

# Cleanup
rm -rf "$TMPDIR"
