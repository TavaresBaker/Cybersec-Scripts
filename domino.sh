#!/bin/sh

echo ">>> Detecting pfSense version..."
PFSENSE_VERSION=$(grep -oE '2\.[0-9]+\.[0-9]+' /etc/version)
echo "Detected version: $PFSENSE_VERSION"

case "$PFSENSE_VERSION" in
  2.7.*)
    PFBLOCKER_PKG="pfSense-pkg-pfBlockerNG-devel"
    ;;
  2.6.*|2.5.*)
    PFBLOCKER_PKG="pfSense-pkg-pfBlockerNG"
    ;;
  *)
    echo "Unsupported pfSense version: $PFSENSE_VERSION"
    exit 1
    ;;
esac

echo ">>> Installing $PFBLOCKER_PKG..."
pkg install -y "$PFBLOCKER_PKG"

echo ">>> Enabling pfBlockerNG..."
sysrc pfblockerng_enable="YES"
sleep 5

# === Prepare DNSBL Blocklists ===
echo ">>> Creating custom DNSBL blocklists..."

mkdir -p /usr/local/pkg/pfblockerng/custom

# Discord and Webhooks
cat <<EOF > /usr/local/pkg/pfblockerng/custom/discord_block.txt
discord.com
discord.gg
discordapp.com
cdn.discordapp.com
media.discordapp.net
gateway.discord.gg
discord.com/api/webhooks
EOF

# Social Media
cat <<EOF > /usr/local/pkg/pfblockerng/custom/social_block.txt
facebook.com
fbcdn.net
instagram.com
twitter.com
x.com
t.co
reddit.com
tiktok.com
snapchat.com
pinterest.com
linkedin.com
tumblr.com
EOF

# Red Teaming Tools (partial example list)
cat <<EOF > /usr/local/pkg/pfblockerng/custom/redteam_block.txt
cobaltstrike.com
bruteratel.com
poshc2.uk
empireproject.io
veil-framework.com
metasploit.com
0x00sec.org
hackforums.net
cracked.io
EOF

# === Backup Config ===
cp /cf/conf/config.xml /cf/conf/config.xml.bak.$(date +%s)

# === Reload & Apply ===
/etc/rc.reload_all

# === Setup Cron for Updates ===
echo ">>> Scheduling pfBlockerNG updates..."
grep -q 'pfblockerng.sh update' /etc/crontab || echo "0 3 * * * root /usr/local/pkg/pfblockerng/pfblockerng.sh update" >> /etc/crontab

echo ">>> pfBlockerNG installed and custom DNSBLs set."
echo ">>> To activate these lists:"
echo "1. Go to Firewall > pfBlockerNG > DNSBL."
echo "2. Add new DNSBL Feeds pointing to the 3 custom lists:"
echo "   /usr/local/pkg/pfblockerng/custom/discord_block.txt"
echo "   /usr/local/pkg/pfblockerng/custom/social_block.txt"
echo "   /usr/local/pkg/pfblockerng/custom/redteam_block.txt"
echo "3. Reload DNS Resolver or reboot pfSense."
