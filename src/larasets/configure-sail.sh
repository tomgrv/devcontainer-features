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

### Init env
zz_log i "Init {B dotenv}"
touch ./.env

### Add APP_KEY to .env if it does not exist, in one line
zz_log i "Ensure APP_KEY is set in .env"
grep -q "APP_KEY" ./.env || echo APP_KEY= >>./.env

### Generate app key
zz_log i "Generate app key"
art config:clear
art config:cache
art key:generate --force

### Daytona support (codeanywhere)
zz_log i "Use {B fwd} to forward ports according to the environment"
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

### Build sail if needed
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ]; then
    sail build
fi

### Seed project
seed
