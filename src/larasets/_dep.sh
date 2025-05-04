#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ ! -x "$HOME/.composer/vendor/bin/dep" ]; then
    zz_log e "Deployer not installed. Please install it first."
    exit 1
fi

#### Test if doppler is installed
if ! command -v doppler >/dev/null 2>&1; then
    zz_log w "Doppler not installed. Running without it."
    $HOME/.composer/vendor/bin/dep "$@"
else
    zz_log i "Doppler installed. Injecting secrets."
    doppler run -- $HOME/.composer/vendor/bin/dep "$@"
fi
