#!/bin/sh

# Define file paths
ORIGINAL_FILE="/etc/rc.initial"
BACKUP_FILE="/etc/rc.initial.backup"
NEW_FILE="/etc/rc.initial"

# Function to restore the original rc.initial file
restore_original() {
    echo "Restoring the original rc.initial file..."
    if [ -f "$BACKUP_FILE" ]; then
        mv "$BACKUP_FILE" "$ORIGINAL_FILE"
        echo "Original rc.initial file restored."
    else
        echo "Backup file not found. Cannot restore."
    fi
}

# Trap to catch script exit (whether success or failure)
trap restore_original EXIT

# Step 1: Backup the original rc.initial file
if [ -f "$ORIGINAL_FILE" ]; then
    mv "$ORIGINAL_FILE" "$BACKUP_FILE"
    echo "Original rc.initial file backed up as rc.initial.backup."
else
    echo "No original rc.initial file found."
    exit 1
fi

# Step 2: Create a new rc.initial file
echo "#!/bin/sh" > "$NEW_FILE"
echo "# New rc.initial file populated with custom section" >> "$NEW_FILE"

# Step 3: Present options to the user
echo "Please select an option to run:"
echo "1. Clean up files"
echo "2. Find users"
echo "3. Find points of entry"
echo "4. Find suspicious processes"
echo "5. Disable web console"
read -p "Enter your choice (1-5): " CHOICE

# Step 4: Download, make executable, and execute the selected option
case $CHOICE in
    1)
        # Clean up files
        echo "Running Clean up files..."
        curl -s https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/restore_files.sh -o /tmp/restore_files.sh
        chmod +x /tmp/restore_files.sh
        /tmp/restore_files.sh
        ;;
    2)
        # Find users
        echo "Running Find users..."
        curl -s https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_added_users.sh -o /tmp/find_added_users.sh
        chmod +x /tmp/find_added_users.sh
        /tmp/find_added_users.sh
        ;;
    3)
        # Find points of entry
        echo "Running Find points of entry..."
        curl -s https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_points_of_entry.sh -o /tmp/find_points_of_entry.sh
        chmod +x /tmp/find_points_of_entry.sh
        /tmp/find_points_of_entry.sh
        ;;
    4)
        # Find suspicious processes
        echo "Running Find suspicious processes..."
        curl -s https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_suspecious_processes.sh -o /tmp/find_suspecious_processes.sh
        chmod +x /tmp/find_suspecious_processes.sh
        /tmp/find_suspecious_processes.sh
        ;;
    5)
        # Disable web console
        echo "Disabling web console..."
        /usr/local/sbin/pfSsh.php playback svc stop lighttpd
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Step 5: Make the new rc.initial executable
chmod +x "$NEW_FILE"

echo "New rc.initial file created and populated with custom section."

# Indicate successful execution
exit 0
