#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

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
#### (`secret` loads Doppler/`.env` secrets and the SSH agent into the environment pm2 captures)
secret $server restart "$app" --update-env ||
    secret env FORCE_COLOR=1 $server start npm --name "$app" -- run "$@"

$server logs "$app" --raw --out
