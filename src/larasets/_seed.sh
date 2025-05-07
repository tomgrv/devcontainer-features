#!/bin/sh
set -e

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
    zz_log w "DB_CONNECTION {Purple $DB_CONNECTION} is not supported yet"
    exit 1
    ;;
esac

### Run migrations
art migrate --seed --graceful --no-interaction
