#!/bin/sh

echo "🔍 Scanning for suspicious processes..."

MATCHES="/tmp/sus_procs.$$"
> "$MATCHES"

# Go through all processes
ps aux | while read -r line; do
  echo "$line" | grep -q "^USER " && continue  # skip header

  PROC_USER=$(echo "$line" | awk '{print $1}')
  PROC_PID=$(echo "$line" | awk '{print $2}')
  CMD=$(echo "$line" | cut -d' ' -f11-)

  case "$CMD" in
    *"/tmp/"*|*"/dev/shm/"*|*"/var/tmp/"*|*"curl "*|*"wget "*|*"nc "*|*"ncat "*|*"base64 "*|*"eval "*|*"bash -i "*|*"perl -e "*|*"python -c "*|*"sh -i "*)
      echo "⚠️ Suspicious: PID $PROC_PID | User: $PROC_USER | $CMD" >> "$MATCHES"
      ;;
  esac
done

# Rogue listeners
echo "🔎 Checking for rogue listening ports..."
netstat -an | grep LISTEN | grep -vE '127\.0\.0\.1|::1|0\.0\.0\.0:22' >> "$MATCHES"

# Show results
echo "\n🎯 Suspicious process findings:\n"
if [ -s "$MATCHES" ]; then
  cat "$MATCHES"
else
  echo "No obvious suspicious processes found."
fi

rm -f "$MATCHES"
