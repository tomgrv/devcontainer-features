#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute artisan command
if [ -n "$LARAVEL_SAIL" ] && sail ps --status running | grep --after-context=1 -q -; then
    zz_log i "Running artisan command in sail container"
    sail artisan "$@"
else
    zz_log i "Running artisan command in local environment"
    php artisan "$@"
fi
