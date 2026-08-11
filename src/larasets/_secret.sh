#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ "$#" -eq 0 ]; then
    zz_log e "No command provided."
    exit 1
fi

if [ -z "$ZZ_SECRET" ]; then
    
    #### Load the SSH key into an agent, best-effort (does not block the command), then run "$@" as-is.
    #### Kept as an argv chain (no string rebuilding) so arguments with quotes, $, or backticks
    #### survive untouched all the way through to the command.
    set -- ssh-agent sh -c 'echo "$SSH_PRIVATE_KEY" | ssh-add - 2>/dev/null; exec "$@"' sh "$@"

    if [ -f ./.env ]; then
        zz_log i "Loading root .env."
        set -- npx --yes dotenv-cli -e ./.env -- "$@"
    else
        zz_log w "No root .env found. Skipping dotenv injection."
    fi

    if command -v doppler >/dev/null 2>&1; then
        zz_log i "Doppler installed. Injecting secrets."
        set -- doppler run -- "$@"
    else
        zz_log w "Doppler not installed. Skipping secret injection."
    fi
fi

exec env ZZ_SECRET=true "$@"
