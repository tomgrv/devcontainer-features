#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}

### Install composer dependencies if composer.json exists
if [ -f $workspace/composer.json ]; then
    echo "Install composer dependencies" | npx --yes chalk-cli --stdin blue
    composer install --ansi --ignore-platform-reqs --no-interaction --no-progress
fi

### Install npm dependencies if package.json exists
if [ -f $workspace/package.json ]; then
    echo "Install npm dependencies" | npx --yes chalk-cli --stdin blue
    npm install --ws --if-present --include-workspace-root || npm install
fi

### Init db if sqlite and not exists
if [ -n "$DB_CONNECTION" ] && [ "$DB_CONNECTION" = "sqlite" ]; then

    ### Set default sqlite db
    if [ -z "$DB_DATABASE" ]; then
        export DB_DATABASE=database/database.sqlite
    fi

    echo "Ensure sqlite db $DB_DATABASE exist" | npx --yes chalk-cli --stdin blue
    touch $workspace/$DB_DATABASE
fi

### Init env
echo "Init dotenv" | npx --yes chalk-cli --stdin blue
touch $workspace/.env

### Add APP_KEY to .env if it does not exist, in one line
grep -q "APP_KEY" $workspace/.env || echo APP_KEY=null >>$workspace/.env
