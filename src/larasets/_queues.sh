#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Stream queue/job worker logs, in Sail when running, else locally
if sail-running; then
    zz_log i "Streaming queue/job logs from Sail-managed pm2"
    exec sail npx --yes pm2 logs sail-queue sail-jobs --raw
else
    zz_log i "Streaming queue/job logs from local pm2"
    exec npx --yes pm2 logs local-queue local-jobs --raw
fi
