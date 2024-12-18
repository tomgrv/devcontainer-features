#!/bin/sh
set -e

### Install composer dependencies if composer.json exists
if [ -f ${containerWorkspaceFolder:-.}/composer.json ]; then
    echo "Install composer dependencies" | npx --yes chalk-cli --stdin blue
    composer install --ansi --ignore-platform-reqs --no-interaction --no-progress
fi

### Install npm dependencies if package.json exists
if [ -f ${containerWorkspaceFolder:-.}/package.json ]; then
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
    touch ${containerWorkspaceFolder:-.}/$DB_DATABASE
fi

### Init env
echo "Init dotenv" | npx --yes chalk-cli --stdin blue
touch ${containerWorkspaceFolder:-.}/.env

### Add APP_KEY to .env if it does not exist, in one line
grep -q "APP_KEY" ${containerWorkspaceFolder:-.}/.env || echo APP_KEY=null >>${containerWorkspaceFolder:-.}/.env

### Init laravel
if [ -f ${containerWorkspaceFolder:-.}/vendor/bin/sail ] && [ "${LARAVEL_SAIL}" -eq "1" ]; then

    echo "Init laravel with sail" | npx --yes chalk-cli --stdin green
    ${containerWorkspaceFolder:-.}/vendor/bin/sail up --build -d
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan key:generate --force
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan config:cache
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan view:cache
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan route:cache
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan optimize:clear
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan migrate --seed --graceful --no-interaction
    ${containerWorkspaceFolder:-.}/vendor/bin/sail npx --yes pm2 --name server_dev start npm -- run dev

elif [ -f ${containerWorkspaceFolder:-.}/artisan ]; then

    echo "Init laravel with artisan" | npx --yes chalk-cli --stdin green
    php -d xdebug.mode=off artisan key:generate --force
    php -d xdebug.mode=off artisan config:cache
    php -d xdebug.mode=off artisan view:cache
    php -d xdebug.mode=off artisan route:cache
    php -d xdebug.mode=off artisan optimize:clear
    php -d xdebug.mode=off artisan migrate --seed --graceful --no-interaction
    npx --yes pm2 --name server_dev start npm -- run dev
else
    echo "No laravel project found" | npx --yes chalk-cli --stdin yellow
fi
