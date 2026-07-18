#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Load environment: Doppler when available, else fall back to .env
if [ -z "${_LARASETS_ENV:-}" ]; then
    export _LARASETS_ENV=1
    if command -v doppler >/dev/null 2>&1; then
        zz_log i "Doppler installed. Injecting secrets."
        exec doppler run -- "$0" "$@"
    elif [ -f ./.env ]; then
        zz_log w "Doppler not installed. Loading .env instead."
        exec npx --yes dotenv -e .env -- "$0" "$@"
    fi
fi

#### Forward smee.io webhook deliveries to the local app
zz_log i "Forwarding {Purple https://smee.io/$SMEE_CHANNEL} to {Purple $APP_URL/$SMEE_TARGET}"
exec npx --yes smee --url "https://smee.io/$SMEE_CHANNEL" --target "$APP_URL/$SMEE_TARGET"
