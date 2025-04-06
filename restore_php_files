#!/bin/sh

# pfSense 2.7.0 - Restore /usr/local/www from official GitHub repo

# Variables
REPO_URL="https://github.com/pfsense/pfsense"
BRANCH="RELENG_2_7_0"
TMP_DIR="/tmp/pfsense_www_restore"

echo "Creating temporary working directory..."
mkdir -p $TMP_DIR && cd $TMP_DIR || exit 1

echo "Cloning pfSense GitHub repository (branch: $BRANCH)..."
git clone --depth=1 --branch $BRANCH $REPO_URL src || {
    echo "Git clone failed. Aborting."
    exit 1
}

# Backup current /usr/local/www
echo "Backing up current /usr/local/www to /usr/local/www.bak..."
cp -a /usr/local/www /usr/local/www.bak || {
    echo "Backup failed. Aborting."
    exit 1
}

# Copy default web files
echo "Restoring default web files from GitHub..."
cp -a src/src/usr/local/www/* /usr/local/www/ || {
    echo "Copy operation failed. Restoring backup."
    cp -a /usr/local/www.bak/* /usr/local/www/
    exit 1
}

# Clean up
echo "Cleaning up temporary files..."
rm -rf $TMP_DIR

echo "Done. /usr/local/www has been restored to defaults from branch $BRANCH."
