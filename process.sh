#!/bin/sh

echo "🔍 Scanning for suspicious processes..."

MATCHES="/tmp/sus_procs.$$"
> "$MATCHES"

ps aux | while read -r line; do
  PROC_USER=$(echo "$line" | awk '{print $1}')
  CMD=$(echo "$line" | cut -d' ' -f11-)

  # Skip header line
  echo "$line" | grep -q "^USER " && continue

  # Heuristics:
  case "$CMD" in
    *"/tmp/"*|*"/dev/shm/"*|*"/var/tmp/"*|*"curl "*|*"wget "*|*"nc "*|*"ncat "*|*"base64 "*|*"eval "*|*"bash -i "*|*"perl -e "*|*"python -c "*|*"sh -i "*)
      echo "⚠️ Suspicious: $CMD (user: $PROC_USER)" >> "$MATCHES"
      ;;
  esac
done

# Check for rogue listeners
echo "🔎 Checking for rogue listening ports..."
netstat -an | grep LISTEN | grep -vE '127\.0\.0\.1|::1|0\.0\.0\.0:22' >> "$MATCHES"

# Results
echo "\n🎯 Suspicious process findings:\n"
if [ -s "$MATCHES" ]; then
  cat "$MATCHES"
else
  echo "No obvious suspicious processes found."
fi

rm -f "$MATCHES"
