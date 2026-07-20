#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Environment-aware orchestration: sail + queue + vite
#### Works the same in Codespaces, dev containers, web and local:
####   - binds 0.0.0.0 + $APP_PORT so a forwarded port is reachable
####   - runs Laravel Sail when Docker is available and wanted, else local PHP
port="${APP_PORT:-8000}"

#### Sail is only an option with a sail binary AND a reachable Docker daemon
sail_possible() {
    { [ -f ./vendor/bin/sail ] || [ -f ./sail ]; } && command -v docker >/dev/null 2>&1
}

#### Local mode is already up if pm2 already manages the local processes
local_running() {
    npx --yes pm2 describe local-serve >/dev/null 2>&1
}

#### Decide the mode:
####   already up (sail)   -> attach sail
####   already up (local)  -> attach local
####   LARAVEL_SAIL=1  -> sail (explicit preference)
####   LARAVEL_SAIL=0  -> local (explicit preference)
####   ambiguous       -> ask (Docker present, no preference)
if sail-running; then
    mode=sail
elif local_running; then
    mode=local
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
    zz_log i "Starting {B Laravel Sail + queue + vite}"
    #### Detached so dependent processes can start against the container
    sail up -d
    #### Delegate each process to srv (pm2 start/restart + secret, Sail-aware)
    srv -q sail-queue art queue:work
    srv -q sail-schedule art schedule:work
    srv -q sail-vite npm run dev
    #### Follow all logs in this terminal
    exec sail npx --yes pm2 logs -f
    ;;
local)
    zz_log i "Serving on {Purple 0.0.0.0:$port} (local PHP + queue + vite)"
    #### Delegate each process to srv (pm2 start/restart + secret)
    srv -q local-serve art serve --host=0.0.0.0 --port=$port
    srv -q local-queue art queue:work
    srv -q local-schedule art schedule:work
    srv -q local-vite npm run dev
    #### Follow all logs in this terminal
    exec npx --yes pm2 logs -f
    ;;
esac
