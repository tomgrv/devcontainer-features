#!/bin/sh

# Mechanical gateway-curl install/divert steps. No policy, no logging, no
# privilege handling — callers decide bindir selection, whether to divert,
# and as-whom to invoke it (image build stage, postCreateCommand via sudo,
# host install, ...).
#
# Usage:
#   install-curl-wrapper-core.sh install <wrapper_src> <bindir>
#   install-curl-wrapper-core.sh divert  <bindir>
#
# 'install' copies <wrapper_src> to <bindir>/gateway-curl.
# 'divert' points the system curl to <bindir>/gateway-curl, keeping the real
# binary at <curl_bin>.real. Idempotent: a no-op if already diverted.

mode="$1"

case "$mode" in
install)
    src="$2"
    bindir="$3"
    [ -n "$src" ] && [ -n "$bindir" ] || exit 1
    mkdir -p "$bindir" 2>/dev/null
    cp "$src" "$bindir/gateway-curl" || exit 1
    chmod 755 "$bindir/gateway-curl"
    ;;
divert)
    bindir="$2"
    [ -n "$bindir" ] || exit 1
    curl_bin=$(command -v curl 2>/dev/null || echo /usr/bin/curl)
    [ -x "${curl_bin}.real" ] && exit 0
    if [ -e "$curl_bin" ]; then
        mv "$curl_bin" "${curl_bin}.real" || exit 1
    fi
    ln -sf "$bindir/gateway-curl" "$curl_bin"
    ;;
*)
    exit 1
    ;;
esac
