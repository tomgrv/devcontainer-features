#!/bin/sh

# Install the gateway-curl wrapper and optionally divert the system curl to it,
# so that SSL inspection gateway forms are handled transparently.
#
# - devcontainer build: diversion enabled by default (feature option "replaceCurl")
# - host install: wrapper is installed as 'gateway-curl' only, diversion is
#   opt-in via GATEWAY_REPLACE_CURL=1

. zz_colors

eval $(
    zz_context "$@"
)

stub_dir="$target/stubs/.devcontainer/.gateway"

wrapper="$stub_dir/gateway-curl.sh"
if [ ! -f "$wrapper" ]; then
    zz_log e "Wrapper not found at {U $wrapper}"
    exit 1
fi
chmod +x "$wrapper"

core="$stub_dir/install-curl-wrapper-core.sh"
if [ ! -f "$core" ]; then
    zz_log e "Core script not found at {U $core}"
    exit 1
fi

# Escalate only when needed and possible
asroot=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
    asroot="sudo"
fi

# Expose the wrapper as 'gateway-curl'
bindir="/usr/local/bin"
if [ -w "$bindir" ]; then
    sh "$core" install "$wrapper" "$bindir"
elif [ -n "$asroot" ] && $asroot sh "$core" install "$wrapper" "$bindir" 2>/dev/null; then
    :
else
    bindir="${HOME:-/tmp}/.local/bin"
    sh "$core" install "$wrapper" "$bindir"
fi
zz_log s "Wrapper installed as {U $bindir/gateway-curl}"

# Decide whether to divert the system curl to the wrapper
if [ -n "${_REMOTE_USER:-}" ] || [ -n "${DEV_CONTAINER_FILE_PATH:-}" ] || [ "${CODESPACES:-}" = "true" ] || [ "${REMOTE_CONTAINERS:-}" = "true" ]; then
    # devcontainer context: honour the feature option (default: true)
    replace=$(echo "${REPLACECURL:-true}" | tr '[:upper:]' '[:lower:]')
else
    # host context: never touch the system curl unless explicitly asked
    case "${GATEWAY_REPLACE_CURL:-}" in
    1 | true | yes) replace=true ;;
    *) replace=false ;;
    esac
fi

if [ "$replace" != "true" ]; then
    zz_log i "System curl left untouched, call {B gateway-curl} explicitly when needed"
    zz_log - "Set {B GATEWAY_REPLACE_CURL=1} before installing to divert the system curl"
    exit 0
fi

curl_bin=$(command -v curl 2>/dev/null || echo /usr/bin/curl)
was_diverted=0
[ -x "${curl_bin}.real" ] && was_diverted=1

if [ "$was_diverted" = "0" ] && [ ! -e "$curl_bin" ]; then
    zz_log w "No system curl found to divert, use {B gateway-curl} explicitly"
    exit 0
fi

if ! $asroot sh "$core" divert "$bindir"; then
    zz_log w "Cannot divert {U $curl_bin} (insufficient rights), use {B gateway-curl} explicitly"
    exit 0
fi

if [ "$was_diverted" = "1" ]; then
    zz_log i "System curl already diverted to the wrapper"
else
    zz_log s "System curl diverted to gateway-curl (real curl kept at ${curl_bin}.real)"
fi
