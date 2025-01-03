#!/bin/sh
set -e

### Init workspace
init

### Build sail if needed
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ]; then
    sail build
fi
