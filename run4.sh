#!/bin/sh

CONFIG="/conf/config.xml"
BACKUP="/conf/config.xml.backup.$(date +%Y%m%d%H%M%S)"

echo "Backing up current config to $BACKUP ..."
cp "$CONFIG" "$BACKUP" || { echo "Backup failed. Aborting."; exit 1; }

# Detect interface names
INTERFACES=$(sed -n '/<interfaces>/,/<\/interfaces>/p' "$CONFIG" | grep -Eo '<[a-z0-9]+>' | sed 's/[<>]//g' | grep -v 'interfaces')

if [ -z "$INTERFACES" ]; then
  echo "No interfaces found in config. Aborting."
  exit 1
fi

echo "Detected interfaces: $INTERFACES"

# Prompt for allowed LAN IP if lan interface exists
if echo "$INTERFACES" | grep -qw "lan"; then
  echo -n "Enter the LAN IP address to allow firewall access (e.g., 192.168.1.2): "
  read ALLOWED_IP
  if ! echo "$ALLOWED_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "Invalid IP format. Exiting."
    exit 1
  fi
fi

now=$(date +%s)
RULES=""

# Build rules dynamically

if echo "$INTERFACES" | grep -qw "wan"; then
RULES="$RULES
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
"
fi

if echo "$INTERFACES" | grep -qw "lan"; then
RULES="$RULES
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
"
fi

if echo "$INTERFACES" | grep -qw "dmz"; then
RULES="$RULES
<rule>
  <tracker>$((now + 2))</tracker>
  <type>block</type>
  <interface>dmz</interface>
  <ipprotocol>inet</ipprotocol>
  <statetype><![CDATA[keep state]]></statetype>
  <source><any/></source>
  <destination><network>(self)</network>
  <descr><![CDATA[Block management access on the DMZ]]></descr>
</rule>
"
fi

if [ -z "$RULES" ]; then
  echo "No applicable interfaces found to add rules. Exiting."
  exit 1
fi

# Insert rules before closing </filter> tag (case-insensitive)
sed -i.bak "/<\/filter>/I i\\
$RULES
" "$CONFIG"

if [ $? -ne 0 ]; then
  echo "Failed to insert rules. Aborting."
  exit 1
fi

echo "Rules inserted successfully."

# Reload firewall rules
/etc/rc.filter_configure

if [ $? -eq 0 ]; then
  echo "Firewall rules reloaded successfully."
else
  echo "Failed to reload firewall rules. Check logs."
fi

exit 0
