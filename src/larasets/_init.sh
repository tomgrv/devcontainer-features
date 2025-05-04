#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install composer dependencies if composer.json exists
if [ -f "./composer.json" ]; then
    zz_log i "Install composer dependencies"
    composer install --ansi --ignore-platform-reqs --no-interaction --no-progress
fi

### Install npm dependencies if package.json exists
if [ -f "./package.json" ]; then
    zz_log i "Install npm dependencies"
    npm install --ws --if-present --include-workspace-root || npm install
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
    zz_log w "DB_CONNECTION {Purple $DB_CONNECTION} is not supported yet"
    exit 1
    ;;
esac

### Init env
zz_log i "Init {B dotenv}"
touch ./.env

### Add APP_KEY to .env if it does not exist, in one line
grep -q "APP_KEY"./.env || echo APP_KEY= >>./.env

### Daytona support (codeanywhere)
if [ -n "$DAYTONA_WS_ID" ]; then
    zz_log i "Daytona/Codeanywhere support"
    fwd daytona
elif [ -n "$CODESPACE_NAME" ]; then
    zz_log i "Github codespace support"
    fwd github
else
    zz_log i "No fwd support"
    fwd local
fi
