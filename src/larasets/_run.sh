#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Load environment (Doppler, else .env) once, then re-exec
if [ -z "${_LARASETS_ENV:-}" ]; then
    export _LARASETS_ENV=1
    exec secret "$0" "$@"
fi

#### Execute npm script, in Sail when running, else locally
if sail-running; then
    zz_log i "Running npm command in sail container"
    sail npm run "$@"
else
    zz_log i "Running npm command in local environment"
    npm run "$@"
fi
