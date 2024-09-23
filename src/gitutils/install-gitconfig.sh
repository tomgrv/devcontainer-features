#!/bin/sh
set -e

### Check if utils are installed
for bin in git-flow dos2unix jq; do
    if [ -n "$(command -v $bin)" ]; then
        echo "$bin is installed."
    elif [ -f /etc/alpine-release ]; then
        apk update
        apk add $bin
    else
        sudo apt-get update
        sudo apt-get install -y $bin
    fi
done

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
echo "Configuring git with <$source/config.json>..."
jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p)|tostring)] | join(" ")' $source/config.json | while read key value; do
    git config --system $key "$value"
    echo "Created config $key => $value"
done

### For each entry in alias.json file next to this file, create corresponding git alias from key and value
echo "Configuring aliases with <$source/alias.json>..."
jq -r 'keys[]' $source/alias.json | dos2unix | while read key; do
    value=$(jq -r ".$key" $source/alias.json)
    git config --system alias.$key "!sh -c '$value' - "
    echo "Created alias $key => $value"
done
