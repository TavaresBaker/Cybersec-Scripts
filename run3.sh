#!/bin/sh

CONFIG="/conf/config.xml"
BACKUP="/conf/config.xml.backup.$(date +%Y%m%d%H%M%S)"
TMP_CONFIG="/tmp/config.xml.tmp"

echo "Backing up current config to $BACKUP ..."
cp "$CONFIG" "$BACKUP" || { echo "Backup failed. Aborting."; exit 1; }

# Detect interfaces from config.xml (interface names are in /config/interfaces/interface/name)
INTERFACES=$(xmllint --xpath "//interfaces/interface/name/text()" "$CONFIG" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$INTERFACES" ]; then
  echo "Failed to detect interfaces or no interfaces found. Aborting."
  exit 1
fi

echo "Detected interfaces: $INTERFACES"

# Ask user for the allowed LAN IP if LAN exists
if echo "$INTERFACES" | grep -qw "lan"; then
  echo -n "Enter the LAN IP address to allow firewall access (e.g., 192.168.1.2): "
  read ALLOWED_IP
  # Basic IP validation
  if ! echo "$ALLOWED_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "Invalid IP address format. Exiting."
    exit 1
  fi
fi

now=$(date +%s)

# Build rules dynamically
RULES=""

# Rule for WAN interface
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

# Rule for LAN interface (only if LAN detected)
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

# Rule for DMZ interface (only if DMZ detected)
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
  echo "No matching interfaces found to apply rules. Exiting."
  exit 1
fi

# Insert the rules before closing </filter> (case-insensitive)
sed -i.bak "/<\/filter>/I i\\
$RULES
" "$CONFIG"

if [ $? -ne 0 ]; then
  echo "Failed to insert rules into config. Aborting."
  exit 1
fi

echo "Config updated. Reloading firewall rules..."

/etc/rc.filter_configure

if [ $? -eq 0 ]; then
  echo "Firewall rules reloaded successfully."
else
  echo "Failed to reload firewall rules. Check pfSense logs."
fi

exit 0
