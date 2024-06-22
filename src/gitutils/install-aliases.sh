#!/bin/sh
set -e

### Install GitFlow
sudo apt-get update
sudo apt-get install -y git-flow dos2unix jq

### Get current directory
feature=$(dirname $(readlink -f $0))

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
echo "Configuring git with <$feature/config.json>..."
jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p)|tostring)] | join(" ")' $feature/config.json | while read key value; do
    git config --system $key "$value"
    echo "Created config $key => $value" 
done

### For each entry in alias.json file next to this file, create corresponding git alias from key and value
echo "Configuring aliases with <$feature/alias.json>..."
jq -r 'keys[]' $feature/alias.json | dos2unix | while read key; do
    value=$(jq -r ".$key" $feature/alias.json)
    git config --system alias.$key "!sh -c '$value' - "
    echo "Created alias $key => $value" 
done

### For each script starting with _, create corresponding git alias without _ from script name
echo "Configuring scripts with <$feature/_xx.sh>..."
for script in $feature/_*.sh; do
    alias=$(basename $script | sed -e 's/^_//g' -e 's/.sh$//g')
    git config --system alias.$alias "!sh -c '$(readlink -f $script)' - "
    echo "Created alias $alias => $(readlink -f $script)"
done
