#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install npm dependencies if package.json exists
if [ -f "./package.json" ]; then

    zz_log i "Make sure common dependencies are declared"
    jq '.dependencies | .[]' ${source:-.}/_package.require.json | xargs -I {} npm install --save {}

    jq '.devDependencies| .[]' ${source:-.}/_package.require.json | xargs -I {} npm install --save-dev {}

    jq '.peerDependencies| .[]' ${source:-.}/_package.require.json | xargs -I {} npm install --save-peer {}

    jq '.globalDependencies| .[]' ${source:-.}/_package.require.json | xargs -I {} npm install -g {}

fi
