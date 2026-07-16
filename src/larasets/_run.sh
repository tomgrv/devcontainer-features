#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute npm script, in Sail when running, else locally
if sail-running; then
    zz_log i "Running npm command in sail container"
    sail npm run "$@"
else
    zz_log i "Running npm command in local environment"
    npm run "$@"
fi
