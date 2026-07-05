#!/bin/sh

# Install the SSL inspection root CA certificate(s) into the system trust store.
#
# Certificates (*.pem) are looked up in the first existing location among:
#   1. $GATEWAY_CERTS_DIR                (explicit override)
#   2. /usr/local/share/gateway/certs    (bind-mounted by the feature at container runtime)
#   3. ./.devcontainer/.gateway/certs    (repository folder, when run on the host)
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

installed=0
for pem in "$certs_dir"/*.pem; do
    if ! grep -q "BEGIN CERTIFICATE" "$pem" 2>/dev/null; then
        zz_log w "Skipping {U $pem}: not a PEM certificate"
        continue
    fi

    crt="/usr/local/share/ca-certificates/$(basename "$pem" .pem).crt"
    if [ -f "$crt" ] && cmp -s "$pem" "$crt"; then
        zz_log i "Certificate {U $crt} already installed"
        continue
    fi

    zz_log i "Installing {U $pem} as {U $crt}"
    $asroot cp "$pem" "$crt" && installed=1
done

if [ "$installed" = "1" ]; then
    $asroot update-ca-certificates >/dev/null
    zz_log s "Gateway root CA installed in the system trust store"
fi
