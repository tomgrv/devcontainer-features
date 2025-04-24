#!/bin/sh
set -e

### Help
if [ "x$1" = "xhelp" ] || [ "x$1" = "x-h" ] || [ "x$1" = "x--help" ] || [ -z "$1" ]; then
    echo "Usage: $0 [remote|local]"
    echo "  remote: set APP_URL and VITE_HOST to use the codespace url"
    echo "  local: remove APP_URL and VITE_HOST to use localhost"
    exit 0
fi >&2

### Check if the environment variables are set
if [ -z "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ] || [ -z "$CODESPACE_NAME" ]; then
    echo "GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN and CODESPACE_NAME must be set, force to local"
    $1=local
fi >&2

### Function to update or replace export entry in .bashrc
setexport() {
    local key="$1"
    local value="$2"

    ### In .bashrc
    local bashrc="$HOME/.bashrc"
    if grep -q "^export $key=" "$bashrc"; then
        # Replace the existing entry
        sed -i "s|^export $key=.*|export $key=$value|" "$bashrc"
    else
        # Add the new entry
        echo "export $key=$value" >>"$bashrc"
    fi

    ### In .env
    local env_file=".env"
    if grep -q "^$key=" "$env_file"; then
        # Replace the existing entry
        sed -i "s|^$key=.*|$key=$value|" "$env_file"
    else
        # Add the new entry
        echo "$key=$value" >>"$env_file"
    fi
}

### Define urls if using a web editor with http port redirection
if [ "x$1" = "xremote" ]; then

    ### update or add APP_URL
    setexport APP_URL "https://$CODESPACE_NAME-${APP_PORT:-80}.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"

    ### update of add VITE_HOST
    setexport VITE_HOST "$CODESPACE_NAME-${VITE_PORT:-5173}.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
fi

### Define urls if using a local editor with localhost port redirection
if [ "x$1" = "xlocal" ] || [ -z "$1" ]; then
    ### remove APP_URL
    setexport APP_URL

    ### remove VITE_HOST
    setexport VITE_HOST
fi
