#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Environment-aware orchestration: sail + queue + jobs + vite
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
    zz_log i "Starting {B Laravel Sail + queue + jobs + vite}"
    #### Detached so dependent processes can start against the container
    sail up -d
    #### Use pm2 to manage multiple services in sail
    #### (`secret` loads Doppler/`.env` secrets and the SSH agent into the environment pm2 captures)
    server='sail npx --yes pm2'
    secret $server start "php -S 0.0.0.0:$port" --name "sail-serve" || secret $server restart "sail-serve" --update-env
    secret $server start "art queue:work" --name "sail-queue" || secret $server restart "sail-queue" --update-env
    secret $server start "art queue:work --queue=jobs" --name "sail-jobs" || secret $server restart "sail-jobs" --update-env
    secret $server start "npm run dev" --name "sail-vite" || secret $server restart "sail-vite" --update-env
    #### Follow all logs in this terminal
    exec $server logs -f
    ;;
local)
    zz_log i "Serving on {Purple 0.0.0.0:$port} (local PHP + queue + jobs + vite)"
    #### Use pm2 to manage multiple services locally
    #### (`secret` loads Doppler/`.env` secrets and the SSH agent into the environment pm2 captures)
    server='npx --yes pm2'
    secret $server start "art serve --host=0.0.0.0 --port=$port" --name "local-serve" || secret $server restart "local-serve" --update-env
    secret $server start "art queue:work" --name "local-queue" || secret $server restart "local-queue" --update-env
    secret $server start "art queue:work --queue=jobs" --name "local-jobs" || secret $server restart "local-jobs" --update-env
    secret $server start "npm run dev" --name "local-vite" || secret $server restart "local-vite" --update-env
    #### Follow all logs in this terminal
    exec $server logs -f
    ;;
esac
