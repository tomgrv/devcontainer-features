#!/bin/sh
export PATH=/usr/bin:$PATH

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

# Apply commitlint rules to the latest commit message
zz_log i "Applying commitlint rules to the latest commit..."
run_local commitlint --edit "$1" && run_local devmoji -e
