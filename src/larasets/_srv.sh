#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ]
then
    server='sail npx --yes pm2'
else
    server='npx --yes pm2'
fi

$server restart server_\$1 || $server --name server_\$1 start npm -- run "\$@"
