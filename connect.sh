#!/bin/sh

echo "🔍 Checking Active Connections on pfSense..."

# Fetch active connections with netstat (with necessary flags)
echo "Listing Active Connections:"

# netstat -an will list all connections, -p will show the process info (if available)
netstat -anp | grep ESTABLISHED

# Optionally, use ss if available
# ss -tuln
# ss -t state established

echo ""
echo "-------------------------"
echo "🎯 Active Connections List:"
echo "-------------------------"

# Display a summary with the connection counts and details for each
netstat -anp | grep ESTABLISHED | awk '{print $5}' | sort | uniq -c | sort -n

echo ""
echo "✅ Active connections check complete."
