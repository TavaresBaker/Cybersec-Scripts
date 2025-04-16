#!/bin/sh

echo "🔍 Checking Active Connections on pfSense..."

# Use ss (more reliable and modern)
echo "Listing Active Connections:"
ss -t state established

echo ""
echo "-------------------------"
echo "🎯 Active Connections List:"
echo "-------------------------"

# Display a summary with the connection counts and details for each
ss -t state established | awk '{print $5}' | sort | uniq -c | sort -n

echo ""
echo "✅ Active connections check complete."
