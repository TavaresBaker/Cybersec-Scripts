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

# === Create custom DNSBL lists ===
echo ">>> Creating custom blocklists..."

mkdir -p /usr/local/pkg/pfblockerng/custom
mkdir -p /usr/local/pkg/pfblockerng/dnsblfeeds

cat <<EOF > /usr/local/pkg/pfblockerng/custom/discord_block.txt
discord.com
discord.gg
discordapp.com
cdn.discordapp.com
media.discordapp.net
gateway.discord.gg
discord.com/api/webhooks
EOF

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

# === Register as DNSBL feeds ===
echo ">>> Creating .feed files..."

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/discord_local.feed
[Discord Blocklist]
file:///usr/local/pkg/pfblockerng/custom/discord_block.txt|Custom_Discord|Block Discord & webhooks
EOF

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/social_local.feed
[Social Media Blocklist]
file:///usr/local/pkg/pfblockerng/custom/social_block.txt|Custom_Social|Block social media domains
EOF

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/redteam_local.feed
[Red Team Tools Blocklist]
file:///usr/local/pkg/pfblockerng/custom/redteam_block.txt|Custom_RedTeam|Block red teaming infrastructure
EOF

# === Run pfBlockerNG update ===
echo ">>> Running pfBlockerNG update to load feeds..."
/usr/local/pkg/pfblockerng/pfblockerng.sh update

# === Restart Unbound DNS Resolver ===
echo ">>> Restarting Unbound DNS Resolver..."
pfSsh.php playback svc restart unbound

# === Optional: Schedule pfBlockerNG auto-updates ===
echo ">>> Adding cron job to update pfBlockerNG daily..."
grep -q 'pfblockerng.sh update' /etc/crontab || echo "0 3 * * * root /usr/local/pkg/pfblockerng/pfblockerng.sh update" >> /etc/crontab

echo "✅ All done! Your pfBlockerNG is live with:"
echo "- Discord and webhook blocking"
echo "- Social media blacklisting"
echo "- Red team infrastructure blocked"
echo ""
echo "👉 Visit Firewall > pfBlockerNG > DNSBL to verify the feeds were imported and are active."
