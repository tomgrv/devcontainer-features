#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

composer_bin="$(composer config -g home 2>/dev/null || echo "${HOME:-/root}/.composer")/vendor/bin"

if [ ! -x "$composer_bin/dep" ]; then
    zz_log e "Deployer not installed. Please install it first."
    exit 1
fi

#### Run deployer with secrets
secret "$composer_bin/dep" "$@"
