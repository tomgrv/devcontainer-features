#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### If no arguments are provided, show usage
eval $(zz_args "Start or restart a pm2-managed process, in Sail when running, else locally" $0 "$@" <<-help
    q -       quiet       Skip following logs after start/restart
    - name    name        pm2 process name
    + cmd     cmd         Command to run
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

#### Restart if already managed, otherwise start a fresh process
#### (`secret` loads Doppler/`.env` secrets and the SSH agent into the environment pm2 captures)
secret $server restart "$name" --update-env ||
    secret env FORCE_COLOR=1 $server start "$cmd" --name "$name"

#### Follow logs unless asked to stay quiet
[ -n "$quiet" ] || $server logs "$name" --raw --out
