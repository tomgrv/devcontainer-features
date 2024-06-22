#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
  exec >/dev/tty 2>&1
fi

# Install commitizen plugins
PLUGINS=$(cat package.json | npx jqn '.config.commitizen.path' | tr -d "'[]:")
npm list --global $PLUGINS 2>/dev/null 1>&2 || npm install --global $PLUGINS 2>/dev/null 1>&2

# Edit commit message
if [ $(grep -cv -e '^#' -e '^$' .git/COMMIT_EDITMSG) -eq 0 ]; then
  (exec </dev/tty && npx --package commitizen -- cz --hook || npx chalk-cli --no-stdin -t "{red !} Unable to start commitizen.") || npx chalk-cli --no-stdin -t "{red !} Commitizen failed."
else
  npx chalk-cli --no-stdin -t "{blue →} Commitizen not relevant. Skipping..."
fi
