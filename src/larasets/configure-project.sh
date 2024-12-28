#!/bin/sh
set -e

init && seed

### Init laravel
if [ -f ${containerWorkspaceFolder:-.}/vendor/bin/sail ] && [ "${LARAVEL_SAIL}" -eq "1" ]; then

    echo "Init laravel with sail" | npx --yes chalk-cli --stdin green
    ${containerWorkspaceFolder:-.}/vendor/bin/sail up --build -d
    ${containerWorkspaceFolder:-.}/vendor/bin/sail npx --yes pm2 --name server_dev start npm -- run dev

elif [ -f ${containerWorkspaceFolder:-.}/artisan ]; then

    echo "Init laravel with artisan" | npx --yes chalk-cli --stdin green
    npx --yes pm2 --name server_dev start npm -- run dev
else
    echo "No laravel project found" | npx --yes chalk-cli --stdin yellow
fi
