#!/bin/sh
#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

composer_bin="$(composer config -g home 2>/dev/null || echo "${HOME:-/root}/.composer")/vendor/bin"

if [ -x "$composer_bin/dep" ]; then
    zz_log s "deployer already globally installed"
else
    zz_log i "Installing deployer globally..."
    composer global require deployer/deployer
fi
