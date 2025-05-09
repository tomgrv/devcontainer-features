#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Apply commitlint rules to the latest commit message
zz_log i "Applying commitlint rules to the latest commit..."
PLUGINS=$(cat package.json | npx --yes jqn '.commitlint.extends' | tr -d "'[]:")
npm list $PLUGINS 2>/dev/null 1>&2 || npm install --no-save $PLUGINS 2>/dev/null 1>&2 && npx --yes commitlint --edit "$1" && npx --yes devmoji -e
