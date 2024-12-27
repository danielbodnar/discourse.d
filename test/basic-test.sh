#!/usr/bin/env bash
set -euo pipefail

# Basic system checks
echo "Testing system configuration..."

# Check if systemd is present
systemctl --version

# Check if discourse user exists
id discourse

# Check if basic directories exist
for dir in /var/www/discourse /home/discourse /var/discourse; do
    [ -d "$dir" ] || exit 1
done

# Check if configuration directory exists
[ -d "/etc/discourse/discourse.conf.d" ] || exit 1

echo "Basic test passed!"
