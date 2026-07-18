#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Load environment (Doppler, else .env) once, then re-exec
if [ -z "${_LARASETS_ENV:-}" ]; then
    export _LARASETS_ENV=1
    exec secret "$0" "$@"
fi

#### Forward smee.io webhook deliveries to the local app
zz_log i "Forwarding {Purple https://smee.io/$SMEE_CHANNEL} to {Purple $APP_URL/$SMEE_TARGET}"
exec npx --yes smee --url "https://smee.io/$SMEE_CHANNEL" --target "$APP_URL/$SMEE_TARGET"
