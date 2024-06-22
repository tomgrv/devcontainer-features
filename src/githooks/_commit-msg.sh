#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Apply commitlint rules to the latest commit message
npx chalk-cli --no-stdin -t "{blue →} Applying commitlint rules to the latest commit..."
PLUGINS=$(cat package.json | npx jqn '.commitlint.extends' | tr -d "'[]:")
npm list --global $PLUGINS 2>/dev/null 1>&2 || npm install --global $PLUGINS 2>/dev/null 1>&2 && npx commitlint --edit "$1" && npx devmoji -e
