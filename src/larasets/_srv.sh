#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute command
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ] && sail ps --status running | grep --after-context=1 -q -; then
    server='sail npx --yes pm2'
else
    server='npx --yes pm2'
fi

$server restart --update-env server_$1 || $server --name server_$1 start "FORCE_COLOR=1 npm -- run \"$@\""
$server log --raw --out server_$1
