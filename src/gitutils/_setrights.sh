#!/bin/sh

#### GOTO DIRECTORY
cd "$(git rev-parse --show-toplevel)"

# Set default permissions for directories
find "." -type d -exec chmod 755 {} \;

# Set default permissions for regular files
find "." -type f -exec chmod 644 {} \;

# Set permissions for executable files (e.g., scripts)
find "." -type f -name "*.sh" -exec chmod 755 {} \;

# Set permissions for sensitive files (e.g., configuration files)
find "." -type f -name "*.conf" -exec chmod 600 {} \;
find "." -type f -name "*.env" -exec chmod 600 {} \;

# Set permissions for specific directories (e.g., logs, cache)
find "./logs" -type d -exec chmod 700 {} \;
find "./cache" -type d -exec chmod 700 {} \;

echo "Access rights have been set according to best practices."
