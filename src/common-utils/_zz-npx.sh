#!/bin/sh

# Run a locally installed npm package binary directly, skipping npx's
# per-invocation resolution overhead. Falls back to npx only when the
# binary isn't present locally, and only if npx itself is available.
# Usage: zz-npx <tool> [args...]

if [ -z "$1" ]; then
    zz_log e "Usage: zz-npx <tool> [args...]"
    exit 1
fi

tool="$1"
shift

bin="${INIT_CWD:-$PWD}/node_modules/.bin/$tool"

if [ -x "$bin" ]; then
    exec "$bin" "$@"
fi

if command -v npx >/dev/null 2>&1; then
    exec npx --yes "$tool" "$@"
fi

zz_log e "Cannot run {B $tool}: not found in node_modules/.bin and npx is not available."
exit 1
