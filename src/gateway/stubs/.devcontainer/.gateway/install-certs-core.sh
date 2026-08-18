#!/bin/sh

# Mechanical CA install: copy *.pem from $1 into the system trust store and
# refresh it. No policy, no logging, no privilege handling — callers decide
# when/how/as-whom to invoke it. Runs unprivileged and privileged alike
# (image build stage, postCreateCommand via sudo, ...).
#
# Usage: install-certs-core.sh <certs_dir>
# Exit codes: 0 = nothing to do / up to date / installed, 1 = copy failed
#
# CERT_STORE_DIR overrides the trust store directory (default:
# /usr/local/share/ca-certificates) and UPDATE_CA_CMD overrides the refresh
# command (default: update-ca-certificates) — used by tests to avoid
# touching the real system trust store.

certs_dir="$1"
store_dir="${CERT_STORE_DIR:-/usr/local/share/ca-certificates}"
update_cmd="${UPDATE_CA_CMD:-update-ca-certificates}"
[ -n "$certs_dir" ] && [ -d "$certs_dir" ] || exit 0
command -v "$update_cmd" >/dev/null 2>&1 || exit 0

installed=0
for pem in "$certs_dir"/*.pem; do
    [ -f "$pem" ] || continue
    grep -q "BEGIN CERTIFICATE" "$pem" 2>/dev/null || continue

    crt="$store_dir/$(basename "$pem" .pem).crt"
    [ -f "$crt" ] && cmp -s "$pem" "$crt" && continue

    cp "$pem" "$crt" || exit 1
    installed=1
done

[ "$installed" = "1" ] && "$update_cmd" >/dev/null
exit 0
