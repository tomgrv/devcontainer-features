#!/bin/sh
export PATH=/usr/bin:$PATH
source=$(dirname $(readlink -f $0))

# Enable colors
if [ -t 1 ]; then
  exec >/dev/tty 2>&1
fi

# Install commitizen plugins
git hook run install-plugins -- '[.config.commitizen.path // "", .commitlint.extends // ""]'



# Edit commit message
if [ $(grep -cv -e '^#' -e '^$' .git/COMMIT_EDITMSG) -eq 0 ]; then
  (exec </dev/tty && npx --yes git-cz --hook || zz_log e "Unable to start commitizen.") || zz_log e "Commitizen failed."
else
  zz_log i "Commitizen not relevant. Skipping..."
fi
