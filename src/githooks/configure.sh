#!/bin/sh

echo "Merge all package folder json files into top level package.json" | npx chalk-cli --stdin blue

### Define current script directory as hook directory
hookDir=$(dirname $(readlink -f $0))
git config hooks.hookDir $hookDir

### Go to the module root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Create package.json if not exists or is empty
if [ ! -f package.json -o  ! -s package.json ]; then
    echo "{}" >package.json
fi

### Merge all package folder json files into top level package.json
find $hookDir -name _*.json | sort | while read file; do

    echo "Merge $file" | npx chalk-cli --stdin yellow
    jq -s '.[1] * .[0]' $file package.json >/tmp/package.json

    #jq -S . /tmp/package.json > ./package.json
    mv -f /tmp/package.json package.json
done
