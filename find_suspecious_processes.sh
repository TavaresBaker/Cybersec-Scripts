#!/bin/sh

echo "🔍 Scanning for suspicious processes..."

MATCHES="/tmp/sus_procs.$$"
> "$MATCHES"

ps aux | while read -r line; do
  echo "$line" | grep -q "^USER " && continue  # skip header

  USER=$(echo "$line" | awk '{print $1}')
  PID=$(echo "$line" | awk '{print $2}')
  CMD=$(echo "$line" | cut -d' ' -f11-)

  echo "$CMD" | grep -Eiq "(curl|wget|nc|ncat|bash -i|perl -e|python -c|sh -i|/tmp/|/var/tmp/|/dev/shm/|base64|eval)" &&
    echo "⚠️ PID $PID | User $USER | $CMD" >> "$MATCHES"
done

echo ""
echo "🔎 Checking for unusual open ports..."

# Filter known legit ports (feel free to tune these)
netstat -an | grep LISTEN | grep -vE '\.22|\.443|\.80|\.53|127\.0\.0\.1|::1' | while read -r line; do
  echo "⚠️ Rogue port: $line" >> "$MATCHES"
done

echo ""
echo "🔍 Checking for suspicious cron jobs..."

# Check for crontab files in common locations and list them if suspicious
for cron_file in /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/* /var/spool/cron/*; do
  if [ -f "$cron_file" ]; then
    # Look for any suspicious commands in the cron jobs
    grep -Eiq "(curl|wget|nc|ncat|bash -i|perl -e|python -c|sh -i|/tmp/|/var/tmp/|/dev/shm/|base64|eval)" "$cron_file" && \
    echo "⚠️ Suspicious cron job in: $cron_file" >> "$MATCHES"
  fi
done

echo ""
echo "🎯 Suspicious Findings:"
echo "-------------------------"
if [ -s "$MATCHES" ]; then
  sort -u "$MATCHES"
else
  echo "✅ Nothing obviously bad detected."
fi

rm -f "$MATCHES"
