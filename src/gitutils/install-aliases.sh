#!/bin/sh
set -e

### Install GitFlow with apt on Ubuntu or apk on Alpine
if [ -f /etc/alpine-release ]; then
    apk update
    apk add git-flow dos2unix jq
else
    apt-get update
    apt-get install -y git-flow dos2unix jq
fi

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

### For each script starting with _, create corresponding git alias without _ from script name
echo "Configuring scripts with <$target/_xx.sh>..."
for script in $target/_*.sh; do
    alias=$(basename $script | sed -e 's/^_//g' -e 's/.sh$//g')
    git config --system alias.$alias "!sh -c '$(readlink -f $script)' - "
    echo "Created alias $alias => $(readlink -f $script)"
done
