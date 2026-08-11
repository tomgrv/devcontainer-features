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

# Check if the current Git branch name is valid
run_local validate-branch-name
