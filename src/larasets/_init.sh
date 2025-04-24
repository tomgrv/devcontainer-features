#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}

### Install composer dependencies if composer.json exists
if [ -f $workspace/composer.json ]; then
    zz_log i "Install composer dependencies"
    composer install --ansi --ignore-platform-reqs --no-interaction --no-progress
fi

### Install npm dependencies if package.json exists
if [ -f $workspace/package.json ]; then
    zz_log i "Install npm dependencies"
    npm install --ws --if-present --include-workspace-root || npm install
fi

### Init db if sqlite and not exists
if [ -n "$DB_CONNECTION" ] && [ "$DB_CONNECTION" = "sqlite" ]; then

    ### Set default sqlite db
    if [ -z "$DB_DATABASE" ]; then
        export DB_DATABASE=database/database.sqlite
    fi

    zz_log i "Ensure sqlite db {Purple $DB_DATABASE} exist"
    touch $workspace/$DB_DATABASE
fi

### Init env
zz_log i "Init {B dotenv}"
touch $workspace/.env

### Add APP_KEY to .env if it does not exist, in one line
grep -q "APP_KEY" $workspace/.env || echo APP_KEY=null >>$workspace/.env
