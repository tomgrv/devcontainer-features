#!/bin/sh

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

# Source the common utils
. $source/src/common-utils/_zz_colors.sh

alias zz_log=$source/src/common-utils/_zz_log.sh

# Track whether this is the root-level invocation to control symlink lifecycle
_install_root="${INSTALL_ROOT_CALL:-1}"
export INSTALL_ROOT_CALL=0

# Prepare for local installation by creating a temporary directory and linking common utils
if [ "$_install_root" = "1" ]; then
    find $source/src/common-utils/ -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
        ln -sf $file $source/src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//')
    done
    export PATH=$PATH:$source/src/common-utils
fi

# Load arguments for the script
eval $(
    $source/src/common-utils/_zz_args.sh "Install features locally" $0 "$@" <<-help
    a -         all         Install all features
    u -         upd         Update all features
    s -         stubs       Install stubs only
    p -         package     Specify package.json file to use
    + features  features    List of features to install
help
)

zz_log i "Installing devcontainer/features"

# Extract tomgrv devcontainer features listed in a devcontainer.json file
devcontainer_features() {
    _file="$1"
    [ -f "$_file" ] || return 0
    sed '/^\s*\/\//d' "$_file" | \
        jq -r '.features // {} | to_entries[] |
            select(.key | contains("tomgrv/devcontainer-features")) |
            .key | split("/")[-1] | split(":")[0]' 2>/dev/null
}

# Find devcontainer.json files in standard locations and extract features
find_devcontainer_features() {
    _search_dir="${1:-.}"

    # Check standard devcontainer file locations in priority order
    for _f in \
        "$_search_dir/.devcontainer/devcontainer.json" \
        "$_search_dir/devcontainer.json" \
        "$_search_dir/.devcontainer.json"; do
        if [ -f "$_f" ]; then
            devcontainer_features "$_f"
            return 0
        fi
    done

    # Check .devcontainer/<folder>/devcontainer.json for multiple configurations
    _found=$(find "$_search_dir/.devcontainer" -maxdepth 2 -mindepth 2 -name "devcontainer.json" 2>/dev/null | head -1)
    if [ -n "$_found" ]; then
        devcontainer_features "$_found"
    fi
}

# If 'all' argument is provided, set stubs and features to install all default features
if [ -n "$all" ]; then
    echo "${Yellow}Add default features${End}"
    stubs=1
    features=$(find_devcontainer_features "$source/stubs")
fi

# If 'upd' argument is provided, set stubs and features to update all features
if [ -n "$upd" ]; then
    echo "${Green}Update features${End}"
    stubs=1
    features=$(find_devcontainer_features "." | tr '\n' ' ')
fi

# If 'package' argument is provided, use the specified package.json file
if [ -n "$package" ]; then
    file="$package"
    if [ ! -f "$file" ]; then
        echo "${Red}File not found: $file${End}"
        exit
    fi

    echo "${Green}Using $file${End}"

    # Extract features from the package.json file if not already set
    if [ -z "$features" ]; then
        features=$(jq -r '.devcontainer.features // {} | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| split("/")[-1] | split(":")[0]' "$file")
    fi
fi

# If no features specified so far, auto-detect from devcontainer files in current directory
if [ -z "$features" ] && [ -z "$stubs" ] && [ -z "$all" ]; then
    detected=$(find_devcontainer_features "." | tr '\n' ' ')
    if [ -n "$detected" ]; then
        features="$detected"
        echo "${Green}Detected features from devcontainer files: $features${End}"
    fi
fi

# Merge all files from the stub folder to the root using git merge-file if stubs are selected
if [ -n "$stubs" ]; then
    echo "${Yellow}Installing stubs from ${UYellow}$source/src/common-utils/${Yellow}...${End}"
    sh "$source/src/common-utils/_configure-feature.sh" -s "$source" .
    echo "${Green}Stubs installed${End}"
fi

# If features are selected, delegate installation of each to install-feat
if [ -n "$features" ]; then

    echo "${Green}Selected features: $features${End}"

    for feature in $features; do
        if [ -n "$stubs" ]; then
            sh "$source/install-feat.sh" "$source" "$feature" --stubs
        else
            sh "$source/install-feat.sh" "$source" "$feature"
        fi
    done

fi

# Remove all links to common utils (only at root-level invocation)
if [ "$_install_root" = "1" ]; then
    echo "Remove temp files..."
    find $source/src/common-utils/ -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
        rm $source/src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//')
    done
fi
