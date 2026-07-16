#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Locate the sail binary (project root wrapper, then vendor)
if [ -f "./sail" ]; then
    sail="./sail"
elif [ -f "./vendor/bin/sail" ]; then
    sail="./vendor/bin/sail"
else
    zz_log e "Laravel Sail not found (no ./sail or ./vendor/bin/sail)"
    exit 1
fi

#### Execute command
sh "$sail" "$@"
