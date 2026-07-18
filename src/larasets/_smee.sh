#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Forward smee.io webhook deliveries to the local app
#### SMEE_CHANNEL/APP_URL/SMEE_TARGET usually come from secrets, so the URL is built
#### inside `secret`'s command line, after Doppler/`.env` have loaded the environment.
zz_log i "Forwarding smee.io webhook deliveries to the local app"
exec secret sh -c 'exec npx --yes smee --url https://smee.io/$SMEE_CHANNEL --target $APP_URL/$SMEE_TARGET'
