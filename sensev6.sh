#!/bin/sh

# Save original rc.initial if not already saved
if [ ! -f /etc/rc.initial.original ]; then
  cp /etc/rc.initial /etc/rc.initial.original
fi

# Replace with altered version if available
if [ -f /etc/rc.initial.custom ]; then
  cp /etc/rc.initial.custom /etc/rc.initial
fi

# Restore on exit
restore_original() {
  echo "Restoring original rc.initial..."
  cp /etc/rc.initial.original /etc/rc.initial
  echo "Done."
  exit
}
trap restore_original INT TERM EXIT

# --- Function: Restore Web and Init System ---
restore_web_and_init() {
  VERSION_RAW=$(cat /etc/version | cut -d'-' -f1)
  BRANCH="RELENG_$(echo "$VERSION_RAW" | tr '.' '_')"
  BRANCHES="$BRANCH master main"
  GITHUB_PFSENSE="https://raw.githubusercontent.com/pfsense/pfsense"
  GITHUB_FREEBSD="https://raw.githubusercontent.com/freebsd/freebsd-src/releng/14.0"
  FAILED_FILES=""

  echo "[*] Detected pfSense version: $VERSION_RAW"
  echo "[*] Trying branches: $BRANCHES"

  cd /root || return 1
  mkdir -p backups_php
  cp -a /usr/local/www backups_php/
  cp -a /usr/local/etc/rc.d backups_php/rc.d/
  echo "[+] Backups complete in /root/backups_php/"

  cd /usr/local || return 1
  fetch "https://codeload.github.com/pfsense/pfsense/zip/refs/heads/${BRANCH}" -o pfsense.zip || return 1
  unzip -oq pfsense.zip
  rm -rf www
  cp -a "pfsense-${BRANCH}/src/usr/local/www" .
  rm -rf pfsense.zip "pfsense-${BRANCH}"
  echo "[✔] /usr/local/www replaced."

  restore_file() {
    LOCAL_PATH="$1"
    RELATIVE_URL="$2"
    for BR in $BRANCHES; do
      URL="${GITHUB_PFSENSE}/${BR}/src${RELATIVE_URL}"
      TMP_FILE="/tmp/$(basename "$LOCAL_PATH")"
      echo "[~] Trying to restore $LOCAL_PATH from $URL"
      curl -fsSL "$URL" -o "$TMP_FILE" && {
        cp "$TMP_FILE" "$LOCAL_PATH"
        echo "[✔] Restored $LOCAL_PATH"
        return 0
      }
    done
    echo "[!] Failed to restore $LOCAL_PATH"
    FAILED_FILES="${FAILED_FILES}\n$LOCAL_PATH"
    return 1
  }

  restore_file "/etc/rc.initial" "/etc/rc.initial"
  restore_file "/etc/inc/config.inc" "/etc/inc/config.inc"
  restore_file "/etc/inc/auth.inc" "/etc/inc/auth.inc"
  chmod +x /etc/rc.initial 2>/dev/null

  echo "[*] Restoring /usr/local/etc/rc.d/* scripts..."
  fetch https://codeload.github.com/pfsense/FreeBSD-ports/zip/refs/heads/devel -o ports.zip
  unzip -oq ports.zip

  if [ -d "FreeBSD-ports-devel" ]; then
    rm -rf /usr/local/etc/rc.d/*
    find FreeBSD-ports-devel -type f -name "*.in" -exec cp {} /usr/local/etc/rc.d/ \;
    echo "[✔] rc.d scripts restored from FreeBSD-ports."
  else
    echo "[!] Failed to restore rc.d scripts"
    FAILED_FILES="${FAILED_FILES}\n/usr/local/etc/rc.d/*"
  fi

  rm -rf ports.zip FreeBSD-ports-devel
  echo "[*] Cleaning up temp PHP sessions..."
  rm -rf /var/tmp/php* /tmp/php*

  echo "[*] Restarting GUI and services..."
  pfSsh.php playback svc restart webgui
  pfSsh.php playback svc restart all

  clear
  echo "----------------------------------------"
  echo "[✔] Restore Completed."
  echo "----------------------------------------"
  echo "The following files were successfully restored:"
  echo "/etc/rc.initial"
  echo "/etc/inc/config.inc"
  echo "/etc/inc/auth.inc"
  echo "/usr/local/www (Web GUI)"
  echo "/usr/local/etc/rc.d (Startup Scripts)"
  echo "----------------------------------------"

  if [ -n "$FAILED_FILES" ]; then
    echo "The following files failed to restore:"
    echo -e "$FAILED_FILES"
  else
    echo "[✔] No files failed to restore."
  fi
}

# --- Function: List and Delete Non-Native Users ---
list_and_delete_users() {
  # Default system users to ignore
  DEFAULT_USERS="admin"

  echo "===[ pfSense Non-Native Users Report ]==="
  echo ""

  # Path to pfSense user config
  USER_XML="/conf/config.xml"
  BACKUP_XML="/conf/config.xml.bak"

  # Extract all users
  ALL_USERS=$(xmllint --xpath '//user/name/text()' $USER_XML 2>/dev/null)

  # Build filtered list
  USER_LIST=""
  INDEX=1

  echo "Found users:"
  for USER in $ALL_USERS; do
      if echo "$DEFAULT_USERS" | grep -qw "$USER"; then
          continue
      fi

      echo "$INDEX) Username: $USER"

      GROUPS=$(xmllint --xpath "//user[name='$USER']/groups/item/text()" $USER_XML 2>/dev/null | xargs)
      [ -z "$GROUPS" ] && GROUPS="(none)"

      DESC=$(xmllint --xpath "string(//user[name='$USER']/descr)" $USER_XML 2>/dev/null)
      [ -z "$DESC" ] && DESC="(no description)"

      echo "   Groups: $GROUPS"
      echo "   Description: $DESC"
      echo "   Defined in: $USER_XML"
      echo ""

      USER_LIST="$USER_LIST$USER\n"
      INDEX=$((INDEX + 1))
  done

  # Prompt for deletion
  echo "Enter the number of the user you want to delete (press Enter for none): "
  read -r USER_NUMBER

  # Validate input
  if [ -n "$USER_NUMBER" ] && echo "$USER_NUMBER" | grep -qE '^[0-9]+$'; then
      DELETE_USER=$(echo -e "$USER_LIST" | sed -n "${USER_NUMBER}p")

      if [ -z "$DELETE_USER" ]; then
          echo "Invalid selection."
          exit 1
      fi

      echo "Selected user for deletion: $DELETE_USER"
      echo "Backing up config to $BACKUP_XML"
      cp "$USER_XML" "$BACKUP_XML"

      echo "Removing user '$DELETE_USER' from config..."
      sed -i '' "/<user>/,/<\/user>/ {/name>$DELETE_USER</!d;}" "$USER_XML"

      echo "Reloading pfSense config..."
      /etc/rc.reload_all

      echo "User '$DELETE_USER' deleted and configuration reloaded."
  else
      echo "No user deleted."
  fi

  echo "=== End of Report ==="
}

# --- Menu ---
while :; do
  clear
  echo "======= pfSense Custom Recovery Menu ======="
  echo " 0) Exit"
  echo " 1) Restore GUI & Init System"
  echo " 2) List and Delete Non-Native Users"
  echo " 3) [empty]"
  echo " 4) [empty]"
  echo " 5) [empty]"
  echo " 6) [empty]"
  echo " 7) [empty]"
  echo " 8) [empty]"
  echo " 9) [empty]"
  echo "10) Open Shell"
  echo "============================================"
  read -p "Choose an option: " opt
  case "$opt" in
    0) break ;;
    1) restore_web_and_init ;;
    2) list_and_delete_users ;;
    10) /bin/tcsh ;;
    *) echo "Invalid option"; sleep 1 ;;
  esac
done
