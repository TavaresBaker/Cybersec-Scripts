#!/bin/sh

echo "🔍 Checking Active Connections on pfSense..."

# Fetch active connections with netstat (correct flags for active connections)
echo "Listing Active Connections:"

# Use netstat with -tn flag to display only TCP connections and -p for process info
netstat -tn | grep ESTABLISHED

# Optionally, use ss (if available) for a more modern approach
# ss -t state established

echo ""
echo "-------------------------"
echo "🎯 Active Connections List:"
echo "-------------------------"

# Display a summary with the connection counts and details for each
netstat -tn | grep ESTABLISHED | awk '{print $5}' | sort | uniq -c | sort -n

echo ""
echo "✅ Active connections check complete."
