#!/bin/sh

# Install the SSL inspection root CA certificate(s) into the system trust store.
#
# Certificates (*.pem) are looked up in the first existing location among:
#   1. $GATEWAY_CERTS_DIR                (explicit override)
#   2. /usr/local/share/gateway/certs    (optional dedicated bind mount, see below)
#   3. ./.devcontainer/.gateway/certs    (repository folder — covers both host use and
#                                         postCreateCommand, since it runs with cwd set
#                                         to the workspace folder, already reachable
#                                         through the workspace's own standard mount)
#
# The dedicated mount at #2 is declared in the stub devcontainer.json (not in this
# feature's own devcontainer-feature.json), so it's opt-in and freely editable per
# project — useful for non-standard workspace layouts, but not required, and it's the
# one thing to remove if it fails to resolve in a nested/docker-outside-of-docker setup
# (its ${localWorkspaceFolder} source needs to be a path the Docker daemon itself can
# see, which isn't guaranteed when it's reached through a mounted docker.sock).
#
# Missing certificates are not an error: the feature stays dormant until the
# user drops the gateway root CA in place and re-runs 'configure-feature gateway'.

. zz_colors

# Escalate only when needed and possible
asroot=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
    asroot="sudo"
fi

# Find the first location containing certificates
certs_dir=""
for dir in "${GATEWAY_CERTS_DIR:-}" /usr/local/share/gateway/certs .devcontainer/.gateway/certs; do
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    if ls "$dir"/*.pem >/dev/null 2>&1; then
        certs_dir="$dir"
        break
    fi
done

if [ -z "$certs_dir" ]; then
    zz_log w "No gateway root CA certificate found (*.pem)"
    zz_log - "Export your SSL inspection root CA in PEM format to {U .devcontainer/.gateway/certs/gateway.pem}"
    zz_log - "then run {B configure-feature gateway} again (or rebuild the container)"
    exit 0
fi

if ! command -v update-ca-certificates >/dev/null 2>&1; then
    zz_log w "update-ca-certificates not available on this system"
    zz_log - "Install the certificates from {U $certs_dir} into your trust store manually"
    exit 0
fi

core="$(dirname "$0")/stubs/.devcontainer/.gateway/_install-certs-core.sh"
if [ ! -f "$core" ]; then
    zz_log e "Core script not found at {U $core}"
    exit 1
fi

zz_log i "Installing certificate(s) from {U $certs_dir}..."
if $asroot sh "$core" "$certs_dir"; then
    zz_log s "Gateway root CA trust store up to date from {U $certs_dir}"
else
    zz_log w "Cannot install certificate(s) from {U $certs_dir} (insufficient privileges)"
    zz_log - "Re-run as root or ensure sudo is available"
fi
