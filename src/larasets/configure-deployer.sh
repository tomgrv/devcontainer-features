#!/bin/sh
#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ -f "$HOME/.composer/vendor/bin/dep" ]; then
    zz_log s "deployer already globally installed"
else
    zz_log i "Installing deployer globally..."
    composer global require deployer/deployer
fi
