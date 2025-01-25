#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ] && sail ps --status running | grep --after-context=1 -q -; then
    sail artisan "$@"
else
    php $workspace/artisan "$@"
fi
