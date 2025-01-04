#!/bin/sh
set -e

### Init workspace
init

### Build sail if needed
if [ -n "$LARAVEL_SAIL" ] && [ "$LARAVEL_SAIL" -eq 1 ]; then
    sail build
fi

echo "Laravel Sail is ready to use. Run 'sail up' to start the containers." | npx --yes chalk-cli --stdin green
