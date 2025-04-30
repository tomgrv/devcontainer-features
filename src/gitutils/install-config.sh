#!/bin/sh

eval $(
    zz_context "$@"
)

# Set Context
GIT_CONFIG_SCOPE="--system"

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    zz_log e "jq is not installed. Please install jq to proceed."
    exit 1
fi

zz_log i "Installing git configuration in {Purple $GIT_CONFIG_SCOPE} scope..."

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
if [ -f "$source/config.json" ]; then
    zz_log i "Configuring git with {U $source/config.json}..."
    jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p)|tostring)] | join(" ")' $source/config.json | while read key value; do
        git config $GIT_CONFIG_SCOPE $key "$value" && zz_log - "Created config $key => $value"
    done
fi

### For each entry in alias.json file next to this file, create corresponding git alias from key and value
if [ -f "$source/alias.json" ]; then
    zz_log i "Configuring aliases with {U $source/alias.json}..."
    jq -r 'keys[]' $source/alias.json | dos2unix | while read key; do
        value=$(jq -r ".$key" $source/alias.json)
        git config $GIT_CONFIG_SCOPE alias.$key "!sh -c '$value' -- \"\$@\"" && zz_log - "Created alias {B $key} => {B $value}"
    done
fi

### For each script starting with _, create corresponding git alias without _ from script name
zz_log i "Configuring scripts with {U $feature/_xx.sh}..."
for script in $target/_*.sh; do
    alias=$(basename $script | sed -e 's/^_//g' -e 's/.sh$//g')
    git config $GIT_CONFIG_SCOPE alias.$alias "!sh -c '$(readlink -f $script) \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8 \$9' -- \"\$@\"" && zz_log - "Created alias {B $alias} => {B $(readlink -f $script)}"
done
