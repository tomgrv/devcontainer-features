#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install composer dependencies if composer.json exists
if [ -f "./composer.json" ]; then

    opts="--prefer-stable --prefer-lowest --minimal-changes --with-all-dependencies --ignore-platform-reqs --dev --no-update"

    zz_log i "Make sure common dependencies are declared"
    jq '.dependencies | .[]' ${source:-.}/_require.json | xargs -I {} composer require $opts {}
    jq '.devDependencies| .[]' ${source:-.}/_require.json | xargs -I {} composer require $opts {}

fi
