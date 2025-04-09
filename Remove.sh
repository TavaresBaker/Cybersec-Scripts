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

# List of directories to check
TARGET_DIRS="
/usr/local/www
/etc
/usr/local/etc/rc.d
"

# Store non-native files
NON_NATIVE="/tmp/non_native_files.txt"
> "$NON_NATIVE"

echo "[*] Scanning for non-native files..."

for DIR in $TARGET_DIRS; do
  CLEAN_DIR="$SRC_DIR$DIR"

  if [ ! -d "$CLEAN_DIR" ]; then
    echo "[-] Skipping $DIR (not in official source)"
    continue
  fi

  find "$DIR" -type f | while read -r LOCAL_FILE; do
    REL_PATH="${LOCAL_FILE#$DIR}"
    REF_FILE="$CLEAN_DIR$REL_PATH"

    if [ ! -f "$REF_FILE" ]; then
      echo "$LOCAL_FILE" >> "$NON_NATIVE"
    fi
  done
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
    echo "[x] Deleting $FILE"
    rm -f "$FILE"
  done < "$NON_NATIVE"
  echo "[✔] Deletion complete."
else
  echo "[!] No files were deleted."
fi

# Cleanup
rm -rf "$TMPDIR"
