#!/bin/sh
set -e

### Define urls if using a web editor with http port redirection
if [ "$1" = "ext" ]; then
    ### update or add APP_URL and VITE_HOST environment variables in .bashrc
    app_url="https://$CODESPACE_NAME-${APP_PORT:-80}.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
    grep -q "export APP_URL" ~/.bashrc && sed -i "s|export APP_URL=.*|export APP_URL=$app_url|g" ~/.bashrc || echo "export APP_URL=$app_url" >>~/.bashrc

    vite_host="$CODESPACE_NAME-${VITE_PORT:-5173}.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
    grep -q "export VITE_HOST" ~/.bashrc && sed -i "s|export VITE_HOST=.*|export VITE_HOST=$vite_host|g" ~/.bashrc || echo "export VITE_HOST=$vite_host" >>~/.bashrc
fi

### Define urls if using a local editor with localhost port redirection
if [ "$1" = "local" ] || [ -z "$1" ]; then
    ### Remove entry from .env
    sed -i "/APP_URL=/d" .env
    sed -i "/VITE_HOST=/d" .env

    ### Remove entry from .bashrc
    grep -v "export APP_URL=" -v "export VITE_HOST=" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
fi
