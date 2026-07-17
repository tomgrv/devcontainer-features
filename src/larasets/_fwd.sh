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

#### Environment variables
if [ -z "$APP_PORT" ]; then
    zz_log w "APP_PORT is not set. Loading from .env file."
    APP_PORT=$(awk -F'=' '/^APP_PORT=/ {print $2}' .env)
else
    zz_log i "APP_PORT is set to $APP_PORT."
    zz_persist -f ./.env APP_PORT "$APP_PORT"
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
    zz_log w "No preset specified. Using provided values."
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
    zz_persist -f ./.env APP_URL "https://${prefix:+${APP_PORT:-80}-}$codespace${suffix:+-${APP_PORT:-80}}${domain:+.$domain}"
    zz_persist -f ./.env ASSET_URL "https://${prefix:+${APP_PORT:-80}-}$codespace${suffix:+-${APP_PORT:-80}}${domain:+.$domain}"
    zz_persist -f ./.env VITE_HOST "${prefix:+${VITE_PORT:-5173}-}$codespace${suffix:+-${VITE_PORT:-5173}}${domain:+.$domain}"
    ;;
local)
    # Set the APP_URL and VITE_HOST for local mode
    zz_persist -f ./.env APP_URL "http://$codespace${domain:+.$domain}:${APP_PORT:-80}"
    zz_persist -f ./.env ASSET_URL "http://$codespace${domain:+.$domain}:${APP_PORT:-80}"
    zz_persist -f ./.env VITE_HOST ""
    ;;
*)
    zz_log e "Invalid mode. Use 'remote' or 'local'."
    exit 1
    ;;
esac

zz_log s "Port forwarding configured successfully on {Purple $mode} mode"
