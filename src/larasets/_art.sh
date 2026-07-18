#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Load environment (Doppler, else .env) once, then re-exec
if [ -z "${_LARASETS_ENV:-}" ]; then
    export _LARASETS_ENV=1
    exec secret "$0" "$@"
fi

#### Execute artisan command, in Sail when running, else locally
if sail-running; then
    zz_log i "Running artisan command in sail container"
    sail artisan "$@"
else
    zz_log i "Running artisan command in local environment"
    php artisan "$@"
fi
