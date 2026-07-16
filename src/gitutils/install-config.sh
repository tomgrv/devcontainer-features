#!/bin/sh

eval $(
    zz_context "$@"
)

scope=${GIT_CONFIG_SCOPE:---system}

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    zz_log e "jq is not installed. Please install jq to proceed."
    exit 1
fi

zz_log i "Installing git configuration in {Purple $scope} scope..."

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
if [ -f "$source/config.json" ]; then
    zz_log i "Configuring git with {U $source/config.json}..."
    jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p)|tostring)] | join(" ")' $source/config.json | while read key value; do
        git config $scope $key "$value" && zz_log - "Created config $key => $value"
    done
fi

### For each entry in alias.json file next to this file, create corresponding git alias from key and value
if [ -f "$source/alias.json" ]; then
    zz_log i "Configuring aliases with {U $source/alias.json}..."
    jq -r 'keys[]' $source/alias.json | while read key; do
        value=$(jq -r ".$key.cmd" $source/alias.json)
        escaped_value=$(printf '%s' "$value" | sed "s/'/'\\''/g")
        git config "$scope" "alias.$key" "!sh -c '$escaped_value' -- \"\$@\"" && zz_log - "Created alias {B $key}"
    done
fi
