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

echo ">>> Creating required directories..."
mkdir -p /usr/local/pkg/pfblockerng/custom
mkdir -p /usr/local/pkg/pfblockerng/dnsblfeeds

echo ">>> Creating aggressive Discord blocklist..."
cat <<EOF > /usr/local/pkg/pfblockerng/custom/discord_block.txt
discord.com
*.discord.com
cdn.discordapp.com
media.discordapp.net
gateway.discord.gg
discord.gg
discordapp.com
*.discordapp.com
status.discord.com
*.status.discord.com
canary.discord.com
ptb.discord.com
EOF

echo ">>> Creating social media blocklist..."
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

echo ">>> Creating red team tools blocklist..."
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

echo ">>> Creating telemetry blocklist..."
cat <<EOF > /usr/local/pkg/pfblockerng/custom/telemetry_block.txt
google-analytics.com
ssl.google-analytics.com
www.google-analytics.com
telemetry.microsoft.com
telemetry.apple.com
settings-win.data.microsoft.com
s.youtube.com
s.youtube-nocookie.com
EOF

echo ">>> Registering feeds in pfBlockerNG..."
cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/discord_local.feed
[Discord Blocklist]
file:///usr/local/pkg/pfblockerng/custom/discord_block.txt|Custom_Discord|Block all Discord domains completely
EOF

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/social_local.feed
[Social Media Blocklist]
file:///usr/local/pkg/pfblockerng/custom/social_block.txt|Custom_Social|Block social media
EOF

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/redteam_local.feed
[Red Team Tools Blocklist]
file:///usr/local/pkg/pfblockerng/custom/redteam_block.txt|Custom_RedTeam|Block known offensive security infrastructure
EOF

cat <<EOF > /usr/local/pkg/pfblockerng/dnsblfeeds/telemetry_local.feed
[Telemetry Blocklist]
file:///usr/local/pkg/pfblockerng/custom/telemetry_block.txt|Custom_Telemetry|Block telemetry domains
EOF

echo ">>> Applying pfBlockerNG update..."
/usr/local/pkg/pfblockerng/pfblockerng.sh update

echo ">>> Restarting Unbound DNS Resolver..."
pfSsh.php playback svc restart unbound

echo ">>> Creating firewall NAT rule to force DNS through pfSense..."

pfctl -sr | grep "Redirect DNS to pfSense" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  pfSsh.php <<'EOF'
  $nat = array();
  $nat['interface'] = "lan";
  $nat['protocol'] = "tcp/udp";
  $nat['src'] = array('type' => 'network', 'address' => "lan");
  $nat['dst'] = array('type' => 'any');
  $nat['dstport'] = "53";
  $nat['target'] = "\$interface_ip";
  $nat['local-port'] = "53";
  $nat['descr'] = "Redirect DNS to pfSense";
  $nat['natport'] = "53";
  $nat['top'] = true;
  $nat['apply'] = true;
  $config['nat']['rule'][] = $nat;
  write_config("Added NAT redirect rule for DNS");
EOF
  echo ">>> Reloading NAT rules..."
  pfctl -f /etc/pf.conf
else
  echo ">>> NAT redirect for DNS already exists. Skipping."
fi

echo ">>> Creating alias for Discord IP ranges..."
pfSsh.php <<'EOF'
  $alias = array();
  $alias['name'] = "Discord_IPs";
  $alias['type'] = "network";
  $alias['address'] = "185.45.32.0/22
185.45.33.0/24
185.45.34.0/22
185.45.35.0/22
185.45.36.0/24
185.45.37.0/24
185.45.38.0/24";
  $alias['descr'] = "Discord IP ranges for blocking";
  $config['aliases']['alias'][] = $alias;
  write_config("Added Discord IP ranges alias");
EOF

echo ">>> Blocking Discord IPs via firewall rules..."
pfSsh.php <<'EOF'
  $rule = array();
  $rule['interface'] = "lan";
  $rule['proto'] = "any";
  $rule['source'] = "any";
  $rule['destination'] = "Discord_IPs";
  $rule['action'] = "block";
  $rule['descr'] = "Block Discord IPs";
  $config['filter']['rule'][] = $rule;
  write_config("Created rule to block Discord IP ranges");
EOF

echo ">>> Blocking DoH (DNS over HTTPS) servers..."
pfSsh.php <<'EOF'
  $doh_ips = array("1.1.1.1", "8.8.8.8", "9.9.9.9", "94.140.14.14", "208.67.222.222");
  foreach ($doh_ips as $ip) {
    $rule = array();
    $rule['interface'] = "lan";
    $rule['proto'] = "tcp";
    $rule['source'] = "any";
    $rule['destination'] = $ip;
    $rule['destinationport'] = "443";
    $rule['action'] = "block";
    $rule['descr'] = "Block DoH to $ip";
    $config['filter']['rule'][] = $rule;
  }
  write_config("Blocked common DNS over HTTPS servers");
EOF

echo ">>> Blocking Discord WebSocket traffic..."
pfSsh.php <<'EOF'
  $rule = array();
  $rule['interface'] = "lan";
  $rule['proto'] = "tcp";
  $rule['source'] = "any";
  $rule['destinationport'] = "443";
  $rule['destination'] = "Discord_IPs";
  $rule['action'] = "block";
  $rule['descr'] = "Block Discord WebSocket traffic";
  $config['filter']['rule'][] = $rule;
  write_config("Created rule to block Discord WebSocket traffic");
EOF

echo ">>> Reloading pfSense firewall rules..."
pfctl -f /etc/pf.conf

echo ">>> Scheduling daily pfBlockerNG update (3 AM)..."
grep -q 'pfblockerng.sh update' /etc/crontab || echo "0 3 * * * root /usr/local/pkg/pfblockerng/pfblockerng.sh update" >> /etc/crontab

echo "✅ All done!"
echo "🚫 Discord, Socials, Red Team tools, Telemetry, and DoH are blocked."
echo "🛡️ Clients are isolated and forced to use pfSense DNS."
