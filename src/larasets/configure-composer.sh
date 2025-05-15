#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install composer dependencies if composer.json exists
if [ -f "./composer.json" ]; then

    zz_log i "Make sure common dependencies are declared"
    jq '.dependencies | .[]' ${source:-.}/require.json | xargs -I {} composer require --ignore-platform-reqs --with-all-dependencies --no-update {}
    jq '.devDependencies| .[]' ${source:-.}/require.json | xargs -I {} composer require --ignore-platform-reqs --with-all-dependencies --dev --no-update {}

fi
