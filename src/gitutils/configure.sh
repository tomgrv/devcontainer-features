#!/bin/sh
set -e

### Init directories
source=$(dirname $(readlink -f $0))
feature=$(basename $source)
echo "Configuring feature <$feature>..."

### Go to the module root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Create package.json if not exists or is empty
echo "Merge all package folder json files into top level package.json" | npx chalk-cli --stdin blue
if [ ! -f package.json -o  ! -s package.json ]; then
    echo "{}" >package.json
fi

### Merge all package folder json files into top level package.json
find $source -name _*.json | sort | while read file; do
    echo "Merge $file" | npx chalk-cli --stdin yellow
    jq -s '.[1] * .[0]' $file package.json >/tmp/package.json && mv -f /tmp/package.json package.json
done

### Call all configure-xxx.sh scripts
find $source -name configure-*.sh | sort | while read file; do
    echo "Run $file" | npx chalk-cli --stdin yellow
    $file
done
