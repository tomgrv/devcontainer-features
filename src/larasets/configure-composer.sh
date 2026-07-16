#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install composer dependencies if composer.json exists
if [ -f "./composer.json" ]; then

    opts="--prefer-stable --minimal-changes --with-all-dependencies --ignore-platform-reqs --no-update"

    zz_log i "Make sure common dependencies are declared"
    
    jq '.dependencies | .[]' ${source:-.}/_composer.require.json | xargs -I {} composer require --no-dev $opts {}

    jq '.devDependencies| .[]' ${source:-.}/_composer.require.json | xargs -I {} composer require --dev $opts {}

    jq '.globalDependencies| .[]' ${source:-.}/_composer.require.json | xargs -I {} composer global require $opts {}

fi
