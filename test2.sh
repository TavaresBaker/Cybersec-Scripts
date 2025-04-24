#!/bin/sh

# Ensure xmlstarlet is installed
if ! command -v xmlstarlet >/dev/null 2>&1; then
  echo "This script requires xmlstarlet. Please install it first."
  exit 1
fi

DEFAULT_USERS="admin"
USER_XML="/conf/config.xml"
BACKUP_XML="/conf/config.xml.bak"

echo "===[ pfSense Non-Native Users Report ]==="
echo ""

ALL_USERS=$(xmlstarlet sel -t -m "//user" -v "name" -n "$USER_XML")

USER_LIST=""
INDEX=1

echo "Found users:"
for USER in $ALL_USERS; do
    if echo "$DEFAULT_USERS" | grep -qw "$USER"; then
        continue
    fi

    echo "$INDEX) Username: $USER"

    GROUPS=$(xmlstarlet sel -t -m "//user[name='$USER']/groups/item" -v "." -o " " "$USER_XML")
    [ -z "$GROUPS" ] && GROUPS="(none)"

    DESC=$(xmlstarlet sel -t -v "//user[name='$USER']/descr" "$USER_XML")
    [ -z "$DESC" ] && DESC="(no description)"

    echo "   Groups: $GROUPS"
    echo "   Description: $DESC"
    echo "   Defined in: $USER_XML"
    echo ""

    USER_LIST="$USER_LIST$USER\n"
    INDEX=$((INDEX + 1))
done

echo "Enter the number of the user you want to delete (press Enter for none): "
read -r USER_NUMBER

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
    xmlstarlet ed -L -d "//user[name='$DELETE_USER']" "$USER_XML"

    echo "Reloading pfSense config..."
    /etc/rc.reload_all

    echo "User '$DELETE_USER' deleted and configuration reloaded."
else
    echo "No user deleted."
fi

echo "=== End of Report ==="
