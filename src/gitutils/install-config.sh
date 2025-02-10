#!/bin/sh

eval $(
    zz_context "$@"
)

# Detect if --system flag can be used for writing
if git config --system test.key test.value >/dev/null 2>&1; then
    GIT_CONFIG_SCOPE="--system"
    git config --system --unset test.key
else
    GIT_CONFIG_SCOPE="--global"
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not installed. Please install jq to proceed."
    exit 1
fi

echo "Installing git configuration in <$GIT_CONFIG_SCOPE> scope..."

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
if [ -f "$source/config.json" ]; then
    echo "Configuring git with <$source/config.json>..."
    jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p)|tostring)] | join(" ")' $source/config.json | while read key value; do
        git config $GIT_CONFIG_SCOPE $key "$value"
        echo "Created config $key => $value"
    done
fi

### For each entry in alias.json file next to this file, create corresponding git alias from key and value
if [ -f "$source/alias.json" ]; then
    echo "Configuring aliases with <$source/alias.json>..."
    jq -r 'keys[]' $source/alias.json | dos2unix | while read key; do
        value=$(jq -r ".$key" $source/alias.json)
        git config $GIT_CONFIG_SCOPE alias.$key "!sh -c '$value' - "
        echo "Created alias $key => $value"
    done
fi

### For each script starting with _, create corresponding git alias without _ from script name
echo "Configuring scripts with <$feature/_xx.sh>..."
for script in $target/_*.sh; do
    alias=$(basename $script | sed -e 's/^_//g' -e 's/.sh$//g')
    git config $GIT_CONFIG_SCOPE alias.$alias "!sh -c '$(readlink -f $script)' - "
    echo "Created alias $alias => $(readlink -f $script)"
done
