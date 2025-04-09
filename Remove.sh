#!/bin/sh

# ===== CONFIGURATION =====
BASELINE_MTREE="/root/pfsense_baseline.mtree"
LOGFILE="/root/filesystem_audit.log"
TMP_DIFF="/tmp/mtree_diff.out"

# ===== STEP 1: Ensure the baseline exists =====
if [ ! -f "$BASELINE_MTREE" ]; then
  echo "ERROR: Baseline mtree file not found at $BASELINE_MTREE"
  echo "Run: mtree -c -p / > $BASELINE_MTREE on a clean install"
  exit 1
fi

echo "=== Filesystem Audit Started at $(date) ===" > "$LOGFILE"

# ===== STEP 2: Generate current mtree state =====
mtree -c -p / > /tmp/current_fs.mtree

# ===== STEP 3: Compare baseline to current =====
mtree -f "$BASELINE_MTREE" -p / > "$TMP_DIFF" 2>>"$LOGFILE"

# ===== STEP 4: Process differences =====
echo "Processing differences..."

while IFS= read -r line; do
  case "$line" in
    *extra*)
      FILE=$(echo "$line" | awk '{print $2}')
      echo "EXTRA FILE: $FILE" >> "$LOGFILE"

      # Uncomment to actually delete:
      # echo "Deleting $FILE" >> "$LOGFILE"
      # rm -rf "$FILE"

      ;;

    *missing*)
      FILE=$(echo "$line" | awk '{print $2}')
      echo "MISSING FILE: $FILE" >> "$LOGFILE"
      # Optional: try to recover or re-add from backup
      ;;

    *modified*)
      FILE=$(echo "$line" | awk '{print $2}')
      echo "MODIFIED FILE: $FILE" >> "$LOGFILE"
      # Optional: restore from backup
      ;;

    *)
      # Other unexpected lines
      echo "OTHER: $line" >> "$LOGFILE"
      ;;
  esac
done < "$TMP_DIFF"

echo "=== Audit Complete ===" >> "$LOGFILE"
echo "See log: $LOGFILE"
