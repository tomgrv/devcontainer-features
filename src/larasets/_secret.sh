#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

if [ "$#" -eq 0 ]; then
    zz_log e "No command provided."
    exit 1
fi

#### Load the SSH key into an agent, best-effort (does not block the command), then run "$@" as-is.
#### Kept as an argv chain (no string rebuilding) so arguments with quotes, $, or backticks
#### survive untouched all the way through to the command.

#### Load environment: Doppler when available, else fall back to .env, else run as-is
if command -v doppler >/dev/null 2>&1; then
    zz_log i "Doppler installed. Injecting secrets."
    exec doppler run -- ssh-agent sh -c 'echo "$SSH_PRIVATE_KEY" | ssh-add - 2>/dev/null; exec "$@"' sh "$@"
elif [ -f ./.env ]; then
    zz_log w "Doppler not installed. Loading .env instead."
    exec npx --yes dotenv -e .env -- ssh-agent sh -c 'echo "$SSH_PRIVATE_KEY" | ssh-add - 2>/dev/null; exec "$@"' sh "$@"
else
    zz_log w "Doppler not installed and no .env file found. Running without injected secrets."
    exec ssh-agent sh -c 'echo "$SSH_PRIVATE_KEY" | ssh-add - 2>/dev/null; exec "$@"' sh "$@"
fi
