#!/bin/sh
set -e

### Install composer dependencies if composer.json exists
if [ -f ${containerWorkspaceFolder:-.}/composer.json ]; then
    composer install --ansi --ignore-platform-reqs --no-interaction --no-progress
fi

### Install npm dependencies if package.json exists
if [ -f ${containerWorkspaceFolder:-.}/package.json ]; then
    npm install --ws --if-present --include-workspace-root || npm install
fi

### Init db if sqlite
if [ -n "$DB_DATABASE" ] && [ -f "$DB_DATABASE" ]; then
    touch $DB_DATABASE
fi

### Init env
touch ${containerWorkspaceFolder:-.}/.env

### Add APP_KEY to .env if it does not exist, in one line
grep -q "APP_KEY" ${containerWorkspaceFolder:-.}/.env || echo APP_KEY=null >> ${containerWorkspaceFolder:-.}/.env

### Init laravel
if [ -f ${containerWorkspaceFolder:-.}/vendor/bin/sail ] && [ "${LARAVEL_SAIL}" -eq "1" ]; then

    ${containerWorkspaceFolder:-.}/vendor/bin/sail up --build -d
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan key:generate --force
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan config:cache
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan view:cache
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan route:cache 
    ${containerWorkspaceFolder:-.}/vendor/bin/sail artisan migrate --seed --graceful
    ${containerWorkspaceFolder:-.}/vendor/bin/sail npx --yes pm2 --name devserver start npm -- run dev

elif [ -f ${containerWorkspaceFolder:-.}/artisan ]; then

    php -d xdebug.mode=off artisan key:generate --force
    php -d xdebug.mode=off artisan config:cache
    php -d xdebug.mode=off artisan view:cache
    php -d xdebug.mode=off artisan route:cache
    php -d xdebug.mode=off artisan migrate --seed --graceful
    npx --yes pm2 --name devserver start npm -- run dev
fi
