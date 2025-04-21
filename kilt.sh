#!/bin/sh

echo "[*] Backing up original /etc/rc.initial..."
cp /etc/rc.initial /etc/rc.initial.bak 2>/dev/null

echo "[*] Writing new reskinned rc.initial menu..."
cat > /etc/rc.initial << 'EOF'
#!/bin/sh
# Custom rc.initial (reskinned)

clear

while true; do
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║        🔧 System Console - pfSense        ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1) Toggle SSH (Enable/Disable)             ║"
    echo "║ 2) Change admin password                   ║"
    echo "║ 3) Clean up files                          ║"
    echo "║ 4) Find users                              ║"
    echo "║ 5) Find points of entry                    ║"
    echo "║ 6) Find suspicious processes               ║"
    echo "║ 7)                                         ║"
    echo "║ 8)                                         ║"
    echo "║ 9) Disable web console                     ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""

    read -p "Select an option (1–9): " option
    echo ""

    case "$option" in
        1)
            /usr/local/bin/php -f /etc/rc.initial.toggle_sshd
            ;;

        2)
            read -p "Enter new admin password: " new_pass
            echo "admin:$new_pass" | chpasswd
            echo "[✓] Admin password changed."
            ;;

        3)
            echo "[*] Running 'Clean up files'..."
            fetch -o /tmp/restore_files.sh https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/restore_files.sh
            chmod +x /tmp/restore_files.sh
            /tmp/restore_files.sh
            ;;

        4)
            echo "[*] Running 'Find users'..."
            fetch -o /tmp/find_added_users.sh https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_added_users.sh
            chmod +x /tmp/find_added_users.sh
            /tmp/find_added_users.sh
            ;;

        5)
            echo "[*] Running 'Find points of entry'..."
            fetch -o /tmp/find_points_of_entry.sh https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_points_of_entry.sh
            chmod +x /tmp/find_points_of_entry.sh
            /tmp/find_points_of_entry.sh
            ;;

        6)
            echo "[*] Running 'Find suspicious processes'..."
            fetch -o /tmp/find_suspecious_processes.sh https://raw.githubusercontent.com/TavaresBaker/Cybersec-Scripts/refs/heads/main/find_suspecious_processes.sh
            chmod +x /tmp/find_suspecious_processes.sh
            /tmp/find_suspecious_processes.sh
            ;;

        7) ;;
        8) ;;

        9)
            echo "[*] Disabling web console..."
            pfSsh.php playback svc stop lighttpd
            echo "[✓] Web console stopped."
            ;;

        *)
            echo "Invalid option. Please choose 1–9."
            ;;
    esac
done
EOF

echo "[*] Setting executable permissions on /etc/rc.initial..."
chmod +x /etc/rc.initial

echo "[✓] Custom rc.initial is now ready. Run it with: /etc/rc.initial"
