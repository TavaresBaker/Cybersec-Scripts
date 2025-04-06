#!/bin/sh

# Change to home directory (root's home on pfSense)
cd /root || exit 1

# Create backup folder
mkdir -p backups_php

# Copy entire www directory and its contents
cp -a /usr/local/www backups_php/

echo "Backup complete. Files copied to /root/backups_php/www"
