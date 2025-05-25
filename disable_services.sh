#!/bin/sh

# === pfSense Unused Services Disabler ===
# Keeps critical and user-defined services (incl. Snort, Suricata, etc.)
# Run as root or from the pfSense console shell

# List of essential and allowed services (case-sensitive)
ESSENTIAL_SERVICES="sshd nginx php-fpm dnsmasq unbound dhcpd syslogd pf snort suricata pfb_dnsbl pfb_tld lighttpd monit"

echo "=== Checking running services... ==="
running_services=$(service -l | awk '{print $1}')

for svc in $running_services; do
  # Skip if service is in the allowed list
  echo "$ESSENTIAL_SERVICES" | grep -qw "$svc" && {
    echo "[KEEP] $svc (allowed)"
    continue
  }

  # Check if service is running
  if service "$svc" onestatus >/dev/null 2>&1; then
    echo "[DISABLE] $svc (currently running)"

    # Disable at boot
    sysrc -q "${svc}_enable=NO" 2>/dev/null

    # Stop it now
    service "$svc" stop 2>/dev/null
  else
    echo "[SKIP] $svc (not running)"
  fi
done

echo "=== Done. Unused services have been disabled. ==="
