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

# ----- Create blocklists -----
create_blocklist() {
  local filename=$1
  shift
  printf "%s\n" "$@" > "/usr/local/pkg/pfblockerng/custom/${filename}.txt"
}

create_blocklist discord_block discord.com '*.discord.com' cdn.discordapp.com media.discordapp.net gateway.discord.gg discord.gg discordapp.com '*.discordapp.com' status.discord.com '*.status.discord.com' canary.discord.com ptb.discord.com
create_blocklist social_block facebook.com fbcdn.net instagram.com twitter.com x.com t.co reddit.com tiktok.com snapchat.com pinterest.com linkedin.com tumblr.com
create_blocklist redteam_block cobaltstrike.com bruteratel.com poshc2.uk empireproject.io veil-framework.com metasploit.com 0x00sec.org hackforums.net cracked.io
create_blocklist telemetry_block google-analytics.com ssl.google-analytics.com www.google-analytics.com telemetry.microsoft.com telemetry.apple.com settings-win.data.microsoft.com s.youtube.com s.youtube-nocookie.com

# ----- Create DNSBL feeds -----
create_feed() {
  cat <<EOF > "/usr/local/pkg/pfblockerng/dnsblfeeds/${1}_local.feed"
[$2]
file:///usr/local/pkg/pfblockerng/custom/${1}.txt|Custom_${2}|$3
EOF
}

create_feed discord_block "Discord Blocklist" "Block all Discord domains completely"
create_feed social_block "Social Media Blocklist" "Block social media"
create_feed redteam_block "Red Team Tools Blocklist" "Block known offensive security infrastructure"
create_feed telemetry_block "Telemetry Blocklist" "Block telemetry domains"

echo ">>> Applying pfBlockerNG update..."
/usr/local/pkg/pfblockerng/pfblockerng.sh update

echo ">>> Restarting Unbound DNS Resolver..."
pfSsh.php playback svc restart unbound

# ----- Create NAT rule to redirect DNS -----
echo ">>> Creating firewall NAT rule to force DNS through pfSense..."
if ! pfctl -sn | grep -q "Redirect DNS to pfSense"; then
  pfSsh.php <<EOF
  require_once("guiconfig.inc");
  require_once("util.inc");
  require_once("filter.inc");
  \$config = config_read_array('nat', 'rule');
  \$nat = array(
    'interface' => 'lan',
    'protocol' => 'tcp/udp',
    'src' => array('type' => 'network', 'address' => 'lan'),
    'dst' => array('type' => 'any'),
    'dstport' => '53',
    'target' => '127.0.0.1',
    'local-port' => '53',
    'natport' => '53',
    'descr' => 'Redirect DNS to pfSense',
    'top' => true
  );
  \$config['nat']['rule'][] = \$nat;
  write_config("Added NAT redirect rule for DNS");
EOF
  pfctl -f /etc/pf.conf
else
  echo ">>> NAT rule already exists. Skipping."
fi

# ----- Create alias for Discord IPs -----
echo ">>> Creating alias for Discord IP ranges..."
pfSsh.php <<EOF
require_once("guiconfig.inc");
\$config = config_read_array('aliases', 'alias');
\$config['aliases']['alias'][] = array(
  'name' => 'Discord_IPs',
  'type' => 'network',
  'address' => '185.45.32.0/22 185.45.33.0/24 185.45.34.0/22 185.45.35.0/22 185.45.36.0/24 185.45.37.0/24 185.45.38.0/24',
  'descr' => 'Discord IP ranges for blocking'
);
write_config("Added Discord IP ranges alias");
EOF

# ----- Block Discord IPs -----
echo ">>> Blocking Discord IPs..."
pfSsh.php <<EOF
require_once("guiconfig.inc");
\$config = config_read_array('filter', 'rule');
\$config['filter']['rule'][] = array(
  'interface' => 'lan',
  'proto' => 'any',
  'source' => 'any',
  'destination' => 'Discord_IPs',
  'action' => 'block',
  'descr' => 'Block Discord IPs'
);
write_config("Blocked Discord IPs");
EOF

# ----- Block DoH -----
echo ">>> Blocking DNS over HTTPS (DoH) servers..."
pfSsh.php <<EOF
require_once("guiconfig.inc");
\$config = config_read_array('filter', 'rule');
\$doh_ips = array("1.1.1.1", "8.8.8.8", "9.9.9.9", "94.140.14.14", "208.67.222.222");
foreach (\$doh_ips as \$ip) {
  \$config['filter']['rule'][] = array(
    'interface' => 'lan',
    'proto' => 'tcp',
    'source' => 'any',
    'destination' => \$ip,
    'destinationport' => '443',
    'action' => 'block',
    'descr' => "Block DoH to \$ip"
  );
}
write_config("Blocked DoH servers");
EOF

# ----- Block Discord WebSockets -----
echo ">>> Blocking Discord WebSocket traffic..."
pfSsh.php <<EOF
require_once("guiconfig.inc");
\$config = config_read_array('filter', 'rule');
\$config['filter']['rule'][] = array(
  'interface' => 'lan',
  'proto' => 'tcp',
  'source' => 'any',
  'destination' => 'Discord_IPs',
  'destinationport' => '443',
  'action' => 'block',
  'descr' => 'Block Discord WebSocket traffic'
);
write_config("Blocked Discord WebSocket traffic");
EOF

echo ">>> Reloading pfSense firewall rules..."
pfctl -f /etc/pf.conf

# ----- Cron job for daily updates -----
echo ">>> Scheduling daily pfBlockerNG update (3 AM)..."
grep -q 'pfblockerng.sh update' /etc/crontab || echo "0 3 * * * root /usr/local/pkg/pfblockerng/pfblockerng.sh update" >> /etc/crontab

echo "✅ Job’s finished. All protections deployed and active."
