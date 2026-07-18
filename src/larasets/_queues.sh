#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Stream the queue worker log, in Sail when running, else locally
if sail-running; then
    zz_log i "Streaming queue log from Sail-managed pm2"
    exec sail npx --yes pm2 logs sail-queue --raw
else
    zz_log i "Streaming queue log from local pm2"
    exec npx --yes pm2 logs local-queue --raw
fi
