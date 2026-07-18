#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Re-exec under Doppler when available, so secrets are in the environment
if [ -z "${_LARASETS_ENV:-}" ] && command -v doppler >/dev/null 2>&1; then
    export _LARASETS_ENV=1
    exec doppler run -- "$0" "$@"
fi

#### Execute artisan command, in Sail when running, else locally
if sail-running; then
    zz_log i "Running artisan command in sail container"
    sail artisan "$@"
else
    zz_log i "Running artisan command in local environment"
    php artisan "$@"
fi
