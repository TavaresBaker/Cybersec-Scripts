#!/bin/sh

# pfSense - List Non-Native Users

# Default system users to ignore
DEFAULT_USERS="admin"

echo "===[ pfSense Non-Native Users Report ]==="
echo ""

# Path to pfSense user config
USER_XML="/conf/config.xml"

# Extract all users
ALL_USERS=$(xmllint --xpath '//user/name/text()' $USER_XML 2>/dev/null)

# Loop through and find non-native users
echo "Found users:"
for USER in $ALL_USERS; do
    if echo "$DEFAULT_USERS" | grep -qw "$USER"; then
        continue
    fi

    echo "- Username: $USER"

    # Get groups the user belongs to
    GROUPS=$(xmllint --xpath "//user[name='$USER']/groups/item/text()" $USER_XML 2>/dev/null | xargs)
    [ -z "$GROUPS" ] && GROUPS="(none)"

    # Get description if exists
    DESC=$(xmllint --xpath "string(//user[name='$USER']/descr)" $USER_XML 2>/dev/null)
    [ -z "$DESC" ] && DESC="(no description)"

    echo "  Groups: $GROUPS"
    echo "  Description: $DESC"
    echo "  Defined in: $USER_XML"
    echo ""
done

echo "=== End of Report ==="
