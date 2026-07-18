#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Load environment (Doppler, else .env) once, then re-exec
if [ -z "${_LARASETS_ENV:-}" ]; then
    export _LARASETS_ENV=1
    exec secret "$0" "$@"
fi

#### If no arguments are provided, show usage
eval $(zz_args "Start or restart the server" $0 "$@" <<-help
    - name    name        Server name
help
)

#### Choose runner: Sail when running, else local
if sail-running; then
    zz_log i "Running pm2 inside Sail"
    server='sail npx --yes pm2'
else
    zz_log i "Running pm2 locally"
    server='npx --yes pm2'
fi

app="server_$name"

#### Restart if already managed, otherwise start a fresh npm process
$server restart "$app" --update-env ||
    FORCE_COLOR=1 $server start npm --name "$app" -- run "$@"

$server logs "$app" --raw --out
