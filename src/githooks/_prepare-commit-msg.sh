#!/bin/sh
export PATH=/usr/bin:$PATH
source=$(dirname $(readlink -f $0))

# Enable colors
if [ -t 1 ]; then
  exec >/dev/tty 2>&1
fi

# Run a tool from node_modules/.bin if present, falling back to npx
run_local() {
  tool=$1
  shift
  bin="${INIT_CWD:-$PWD}/node_modules/.bin/$tool"
  if [ -x "$bin" ]; then
    "$bin" "$@"
  else
    npx --yes "$tool" "$@"
  fi
}

# Install commitizen plugins
git hook run install-plugins -- -g '[.config.commitizen.path // "", .commitlint.extends // ""]'

# Edit commit message
if [ $(grep -cv -e '^#' -e '^$' .git/COMMIT_EDITMSG) -eq 0 ]; then
  (exec </dev/tty && run_local git-cz --hook || zz_log e "Unable to start commitizen.") || zz_log e "Commitizen failed."
else
  zz_log i "Commitizen not relevant. Skipping..."
fi
