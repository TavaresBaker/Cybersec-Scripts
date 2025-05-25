#!/bin/sh

# Ask for IP address to allow
echo -n "Enter the LAN IP address to allow firewall access (e.g., 192.168.1.2): "
read ALLOWED_IP

# Sanitize input with a simple regex (IPv4 check)
if ! echo "$ALLOWED_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
  echo "Invalid IP address format. Exiting."
  exit 1
fi

# Get current epoch time
now=$(date +%s)

# Generate XML rules
cat <<EOF > /tmp/custom_fw_rules.xml
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

echo "Firewall rules have been generated in /tmp/custom_fw_rules.xml"
