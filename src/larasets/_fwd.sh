#!/bin/sh

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Configure port forwarding" $0 "$@" <<-help
        d domain        domain      Port formading domain
        c codespace     codespace   Codespace name
        p -             prefix      Port to prefix 
        s -             suffix      Port to suffix
        - preset        preset      Port forwarding preset (github/daytona/local)
help
)

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Function to persist an env var in .env and, when available, in Doppler
#### (Doppler is the durable store: unlike $HOME/.bashrc, it survives a
#### container rebuild — see the `doppler` feature option / DOPPLER_CONFIG).
setexport() {
    local key="$1"
    local value="$2"

    touch ./.env

    ### In .env (source of truth read by the Laravel app itself)
    local env_file=".env"
    if grep -q "^$key=" "$env_file"; then
        # Replace the existing entry
        sed -i "s|^$key=.*|$key=$value|" "$env_file"
    else
        # Add the new entry
        echo "$key=$value" >>"$env_file"
    fi

    ### In Doppler, so the value survives a container rebuild
    if command -v doppler >/dev/null 2>&1; then
        if doppler secrets set "$key=$value" --silent >/dev/null 2>&1; then
            zz_log i "$key persisted to Doppler"
        else
            zz_log w "$key: Doppler secrets set failed (not logged in / no config linked), kept in .env only"
        fi
    fi

    zz_log i "$key: $value"
}

#### Environment variables
if [ -z "$APP_PORT" ]; then
    zz_log w "APP_PORT is not set. Loading from .env file."
    APP_PORT=$(awk -F'=' '/^APP_PORT=/ {print $2}' .env)
else
    zz_log i "APP_PORT is set to $APP_PORT."
    setexport APP_PORT "$APP_PORT"
fi

#### Load preset values
case "$preset" in
github)
    domain="$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
    codespace="$CODESPACE_NAME"
    suffix="-suffix"
    mode="remote"
    ;;
daytona)
    domain="$DAYTONA_WS_DOMAIN"
    codespace="$DAYTONA_WS_ID"
    prefix="-prefix"
    mode="remote"
    ;;
local)
    domain=""
    codespace="localhost"
    prefix=""
    suffix=""
    mode="local"
    ;;
*)
    if [ -z "$domain" ]; then
        zz_log e "Domain is required."
        exit 1
    fi
    if [ -z "$codespace" ]; then
        zz_log e "Codespace is required."
        exit 1
    fi
    if [ -z "$prefix" -o -z "$suffix" ]; then
        zz_log e "One of prefix or suffix is required."
        exit 1
    fi
    mode="remote"
    ;;
esac

case "$mode" in
remote)
    # Set the APP_URL and VITE_HOST for remote mode
    setexport APP_URL "https://${prefix:+${APP_PORT:-80}-}$codespace${suffix:+-${APP_PORT:-80}}${domain:+.$domain}"
    setexport ASSET_URL "https://${prefix:+${APP_PORT:-80}-}$codespace${suffix:+-${APP_PORT:-80}}${domain:+.$domain}"
    setexport VITE_HOST "${prefix:+${VITE_PORT:-5173}-}$codespace${suffix:+-${VITE_PORT:-5173}}${domain:+.$domain}"
    ;;
local)
    # Set the APP_URL and VITE_HOST for local mode
    setexport APP_URL "http://$codespace${domain:+.$domain}:${APP_PORT:-80}"
    setexport ASSET_URL "http://$codespace${domain:+.$domain}:${APP_PORT:-80}"
    setexport VITE_HOST ""
    ;;
*)
    zz_log e "Invalid mode. Use 'remote' or 'local'."
    exit 1
    ;;
esac

zz_log s "Port forwarding configured successfully on {Purple $mode} mode"
