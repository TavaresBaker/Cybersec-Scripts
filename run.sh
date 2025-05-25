#!/bin/sh

CONFIG="/conf/config.xml"
BACKUP="/conf/config.xml.backup.$(date +%Y%m%d%H%M%S)"
TMP_CONFIG="/tmp/config.xml.tmp"

echo "Backing up current config to $BACKUP ..."
cp "$CONFIG" "$BACKUP"
if [ $? -ne 0 ]; then
  echo "Failed to backup config. Aborting."
  exit 1
fi

# Ask user for the allowed LAN IP
echo -n "Enter the LAN IP address to allow firewall access (e.g., 192.168.1.2): "
read ALLOWED_IP

# Basic IP validation
if ! echo "$ALLOWED_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
  echo "Invalid IP address format. Exiting."
  exit 1
fi

# Prepare rules XML snippet to inject (timestamps to avoid collisions)
now=$(date +%s)

RULES=$(cat <<EOF
<rule>
  <tracker>$now</tracker>
  <type>block</type>
  <interface>wan</interface>
  <ipprotocol>inet</ipprotocol>
  <statetype><![CDATA[keep state]]></statetype>
  <source><any/></source>
  <destination><network>(self)</network>
  <descr><![CDATA[Block management access from the WAN interface]]></descr>
</rule>

<rule>
  <tracker>$((now + 1))</tracker>
  <type>block</type>
  <interface>lan</interface>
  <ipprotocol>inet</ipprotocol>
  <statetype><![CDATA[keep state]]></statetype>
  <source>
    <address>$ALLOWED_IP</address>
    <not></not>
  </source>
  <destination><network>(self)</network>
  <descr><![CDATA[Restrict management access on the LAN]]></descr>
</rule>

<rule>
  <tracker>$((now + 2))</tracker>
  <type>block</type>
  <interface>wan</interface>
  <ipprotocol>inet</ipprotocol>
  <statetype><![CDATA[keep state]]></statetype>
  <source><any/></source>
  <destination><network>(self)</network>
  <descr><![CDATA[Block management access on the DMZ]]></descr>
</rule>
EOF
)

# Insert the rules inside the <filter> section before the closing </filter> tag
# Using awk to preserve formatting and inject rules

awk -v rules="$RULES" '
  /<\/filter>/ {
    print rules
  }
  { print }
' "$CONFIG" > "$TMP_CONFIG"

if [ $? -ne 0 ]; then
  echo "Failed to insert rules into config. Aborting."
  exit 1
fi

# Overwrite original config.xml with modified version
mv "$TMP_CONFIG" "$CONFIG"

echo "Config updated. Reloading firewall rules..."

# Reload firewall rules for changes to take effect
/etc/rc.filter_configure

if [ $? -eq 0 ]; then
  echo "Firewall rules reloaded successfully."
else
  echo "Failed to reload firewall rules. Check pfSense logs."
fi

exit 0
