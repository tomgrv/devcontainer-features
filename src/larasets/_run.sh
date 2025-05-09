#!/bin/sh
set -e

if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ] && sail ps --status running | grep --after-context=1 -q -; then
    sail npm run "$@"
else
    npm run "$@"
fi
