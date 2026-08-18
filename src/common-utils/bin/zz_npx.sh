#!/bin/sh

# Run a locally installed npm package binary directly, skipping npx's
# per-invocation resolution overhead. Falls back to npx only when the
# binary isn't present locally, and only if npx itself is available.
# Usage: zz_npx [-s] <tool> [args...]
#
# The npx fallback may install <tool> on the fly, so its lifecycle scripts
# are untrusted and skipped (--ignore-scripts) by default. Pass -s to allow
# them to run.

withscripts=0
if [ "$1" = "-s" ]; then
    withscripts=1
    shift
fi

if [ -z "$1" ]; then
    zz_log e "Usage: zz_npx [-s] <tool> [args...]"
    exit 1
fi

tool="$1"
shift

bin="${INIT_CWD:-$PWD}/node_modules/.bin/$tool"

if [ -x "$bin" ]; then
    exec "$bin" "$@"
fi

if command -v npx >/dev/null 2>&1; then
    if [ "$withscripts" = "1" ]; then
        exec npx --yes "$tool" "$@"
    else
        exec npx --yes --ignore-scripts "$tool" "$@"
    fi
fi

zz_log e "Cannot run {B $tool}: not found in node_modules/.bin and npx is not available."
exit 1
