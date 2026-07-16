#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Environment-aware app server.
#### Works the same in Codespaces, dev containers, web and local:
####   - binds 0.0.0.0 + $APP_PORT so a forwarded port is reachable
####   - runs Laravel Sail when Docker is available and wanted, else local PHP
port="${APP_PORT:-8000}"

#### Sail is only an option with a sail binary AND a reachable Docker daemon
sail_possible() {
    { [ -f ./vendor/bin/sail ] || [ -f ./sail ]; } && command -v docker >/dev/null 2>&1
}

#### Decide the mode:
####   already up      -> attach
####   LARAVEL_SAIL=1  -> sail (explicit preference)
####   LARAVEL_SAIL=0  -> local (explicit preference)
####   ambiguous       -> ask (Docker present, no preference)
if sail-running; then
    mode=sail
elif [ "${LARAVEL_SAIL:-}" = "1" ] && sail_possible; then
    mode=sail
elif [ "${LARAVEL_SAIL:-}" = "0" ]; then
    mode=local
elif sail_possible && zz_ask "Yn" "Start with Laravel Sail (Docker)?"; then
    mode=sail
else
    mode=local
fi

case "$mode" in
sail)
    zz_log i "Starting {B Laravel Sail}"
    #### Detached so dependent watchers can start against the container
    sail up -d
    #### Follow the container logs in this terminal
    exec sail logs -f
    ;;
local)
    zz_log i "Serving on {Purple 0.0.0.0:$port} (local PHP)"
    exec art serve --host=0.0.0.0 --port="$port"
    ;;
esac
