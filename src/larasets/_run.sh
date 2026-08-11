#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute npm script, in Sail when running, else locally
#### (`secret` loads Doppler/`.env` secrets and the SSH agent around it)
if sail-running; then
    zz_log i "Running npm command in sail container"
    exec secret sail npm run "$@"
else
    zz_log i "Running npm command in local environment"
    exec secret npm run "$@"
fi
