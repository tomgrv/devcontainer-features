#!/bin/sh
set -e

### Check if feature is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <feature>"
    exit 1
fi

### Init directories
export feature=$1
export source=/usr/local/share/$1

### Get indent size from devcontainer.json with jq, default to 2 if not found
export tabSize=$(sed 's/\/\/.*//' .devcontainer/devcontainer.json | jq '.customizations.vscode.settings["editor.tabSize"] // 2')

echo "Configuring feature <$feature>"
echo "from <$source>"

### Go to the module root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Log
echo "Merge all package folder json files into top level package.json" | npx --yes chalk-cli --stdin blue

### Create package.json if not exists or is empty
if [ ! -f package.json -o ! -s package.json ]; then
    # Create empty package.json
    echo "{}" >package.json
else
    # Pre-sort
    npx --yes sort-package-json
fi

### Merge all package folder json files into top level package.json
find $source -name _*.json | sort | while read file; do
    echo "Merge $file" | npx --yes chalk-cli --stdin yellow
    jq --indent ${tabSize:-2} -s '.[0] * .[1]' $file package.json >/tmp/package.json && mv -f /tmp/package.json package.json
done

### Call all configure-xxx.sh scripts
find $source -name configure-*.sh | sort | while read file; do
    echo "Run $file" | npx --yes chalk-cli --stdin yellow
    $file || true
done

### Sort package.json
npx --yes sort-package-json
