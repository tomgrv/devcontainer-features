#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Install commitizen plugins
git hook run install-plugins -- '.commitlint.extends//""'

# Apply commitlint rules to the latest commit message
zz_log i "Applying commitlint rules to the latest commit..."
npx --yes commitlint --edit "$1" && npx --yes devmoji -e
