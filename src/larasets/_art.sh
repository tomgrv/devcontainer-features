#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute artisan command, in Sail when running, else locally
if sail-running; then
    zz_log i "Running artisan command in sail container"
    sail artisan "$@"
else
    zz_log i "Running artisan command in local environment"
    php artisan "$@"
fi
