#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ "$#" -eq 0 ]; then
    zz_log e "No command provided."
    exit 1
fi

#### Load the SSH key into an agent, best-effort (does not block the command)
command="ssh-agent sh -c \"echo '\$SSH_PRIVATE_KEY' | ssh-add - 2>/dev/null; "$(printf "'%s' " "$@")"\""

#### Load environment: Doppler when available, else fall back to .env, else run as-is
if command -v doppler >/dev/null 2>&1; then
    zz_log i "Doppler installed. Injecting secrets."
    doppler run --command "$command"
elif [ -f ./.env ]; then
    zz_log w "Doppler not installed. Loading .env instead."
    npx --yes dotenv -e .env -- sh -c "$command"
else
    zz_log w "Doppler not installed and no .env file found. Running without injected secrets."
    sh -c "$command"
fi
