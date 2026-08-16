#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null 2>&1 || true

#### Exit 0 if a Laravel Sail container is up, 1 otherwise.
#### Single source of truth for the Sail-aware wrappers (art/run/srv).

# No sail binary => not running
[ -f "./vendor/bin/sail" ] || [ -f "./sail" ] || exit 1

# Ask compose for running containers; any output means Sail is up
if sail ps --status running -q 2>/dev/null | grep -q .; then
    exit 0
fi

exit 1
