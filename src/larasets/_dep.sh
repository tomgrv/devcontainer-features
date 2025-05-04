#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ ! -x "$HOME/.composer/vendor/bin/dep" ]; then
    zz_log e "Deployer not installed. Please install it first."
    exit 1
fi

$HOME/.composer/vendor/bin/dep "$@"
