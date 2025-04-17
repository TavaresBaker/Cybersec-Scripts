#!/bin/sh

# pfSense - List Non-Native Users with Delete Option

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
