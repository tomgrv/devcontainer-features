#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Re-exec under Doppler when available, so secrets are in the environment
if [ -z "${_LARASETS_ENV:-}" ] && command -v doppler >/dev/null 2>&1; then
    export _LARASETS_ENV=1
    exec doppler run -- "$0" "$@"
fi

### Default DB_CONNECTION
if [ -z "$DB_CONNECTION" ]; then
    export DB_CONNECTION=sqlite
fi

### Init db if sqlite and not exists
case $DB_CONNECTION in
sqlite)
    zz_log i "DB_CONNECTION is {Purple $DB_CONNECTION}"
    ### Set default sqlite db
    if [ -z "$DB_DATABASE" ]; then
        export DB_DATABASE=database/database.sqlite
    fi

    zz_log i "Ensure sqlite db {Purple $DB_DATABASE} exist"
    touch ./$DB_DATABASE
    ;;
*)
    zz_log i "DB_CONNECTION is {Purple $DB_CONNECTION}, using existing database server"
    ;;
esac

### Run migrations
art migrate --seed --graceful --no-interaction
