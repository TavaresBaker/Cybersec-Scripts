# Delete the <user> block with <name> matching the selected username
awk -v user="$ESCAPED_USER" '
BEGIN { in_block = 0; block = "" }
/<user>/ { in_block = 1; block = $0 ORS; next }
/<\/user>/ {
    block = block $0 ORS;
    if (block ~ "<name>" user "</name>") {
        in_block = 0;
        block = "";
        next;  # skip writing the block
    } else {
        printf "%s", block;
        in_block = 0;
        block = "";
        next;
    }
}
{
    if (in_block) {
        block = block $0 ORS;
    } else {
        print;
    }
}
' "$BACKUP_XML" > "$USER_XML"
