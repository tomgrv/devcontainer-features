#!/bin/sh
set -e

if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ] && sail ps --status running | grep --after-context=1 -q -; then
    zz_log i "Running npm command in sail container"
    sail npm run "$@"
else
    zz_log i "Running npm command in local environment"
    npm run "$@"
fi
