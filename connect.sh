#!/bin/sh

echo "🔍 Checking Active Connections on pfSense..."

# Fetch active connections with netstat (or ss if preferred)
echo "Listing Active Connections:"
netstat -anp | grep ESTABLISHED

# Optionally, you can use ss instead of netstat (if available)
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
