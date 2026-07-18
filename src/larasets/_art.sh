#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute artisan command, in Sail when running, else locally
#### (`secret` loads Doppler/`.env` secrets and the SSH agent around it)
if sail-running; then
    zz_log i "Running artisan command in sail container"
    exec secret sail artisan "$@"
else
    zz_log i "Running artisan command in local environment"
    exec secret php artisan "$@"
fi
