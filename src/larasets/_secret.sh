#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ "$#" -eq 0 ]; then
    zz_log e "No command provided."
    exit 1
fi

if [ ! -x "$HOME/.composer/vendor/bin/dep" ]; then
    zz_log e "Deployer not installed. Please install it first."
    exit 1
fi

#### Initialize command
command="ssh-agent sh -c 'echo \"\$SSH_PRIVATE_KEY\" | ssh-add - && $@'"

#### Test if doppler is installed
if ! command -v doppler >/dev/null 2>&1; then
    zz_log w "Doppler not installed. Running without it."
    $command
else
    zz_log i "Doppler installed. Injecting secrets."
    doppler run --command "$command"
fi
