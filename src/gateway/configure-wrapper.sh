#!/bin/sh

set -eu

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

GATEWAY_SOURCE=".devcontainer/.gateway/gateway-curl.sh"
CURLRC_SOURCE=".devcontainer/.gateway/root/.curlrc"
GATEWAY_TARGET="/usr/local/bin/gateway-curl"
CURL_BIN="/usr/bin/curl"
CURL_REAL_BIN="/usr/bin/curl.real"
CURRENT_USER="${SUDO_USER:-$(id -un)}"
CURRENT_HOME="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"

run_as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

if [ ! -f "$GATEWAY_SOURCE" ]; then
	zz_log e "Missing gateway curl wrapper: {U $GATEWAY_SOURCE}"
	exit 1
fi

if [ ! -f "$CURLRC_SOURCE" ]; then
	zz_log e "Missing curl configuration: {U $CURLRC_SOURCE}"
	exit 1
fi

if [ -z "$CURRENT_HOME" ] || [ ! -d "$CURRENT_HOME" ]; then
	zz_log e "Could not resolve home directory for user: {U $CURRENT_USER}"
	exit 1
fi

zz_log i "Installing gateway curl wrapper to {U $GATEWAY_TARGET}"
run_as_root install -m 755 "$GATEWAY_SOURCE" "$GATEWAY_TARGET"

if [ -L "$CURL_BIN" ] && [ "$(readlink -f "$CURL_BIN")" = "$GATEWAY_TARGET" ]; then
	zz_log w "curl is already routed through gateway"
else
	if [ ! -e "$CURL_REAL_BIN" ]; then
		zz_log i "Preserving original curl as {U $CURL_REAL_BIN}"
		run_as_root mv "$CURL_BIN" "$CURL_REAL_BIN"
	fi

	zz_log i "Linking {U $CURL_BIN} to {U $GATEWAY_TARGET}"
	run_as_root ln -sfn "$GATEWAY_TARGET" "$CURL_BIN"
fi

zz_log i "Installing curl configuration to {U $CURRENT_HOME/.curlrc}"
run_as_root install -m 644 "$CURLRC_SOURCE" "$CURRENT_HOME/.curlrc"
run_as_root chown "$CURRENT_USER":"$(id -gn "$CURRENT_USER")" "$CURRENT_HOME/.curlrc"

zz_log s "Gateway curl wrapper configured for {U $CURRENT_USER}"

