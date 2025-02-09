#!/bin/sh

# Go to the root directory of the git repository
cd $(git rev-parse --show-toplevel) >/dev/null

# Add common utils to the PATH
export PATH=$PATH:$(dirname $0)/src/common-utils

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

# Prepare for local installation by creating a temporary directory and linking common utils
mkdir -p /tmp/common-utils
find $PWD/$(dirname $0)/src/common-utils/ -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    # Create a symbolic link in /usr/local/bin with the script name (without the leading underscore and .sh extension)
    link=/tmp/common-utils/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link
done
export PATH=$PATH:/tmp/common-utils

# Load arguments for the script
. zz_args "Install features locally" $0 "$@" <<-help
    a -         all         Install all features
    u -         upd         Update all features
    s -         stubs       Install stubs only
    p -         package     Specify package.json file to use
    + features  features    List of features to install
help

# If 'all' argument is provided, set stubs and features to install all default features
if [ -n "$all" ]; then
    echo "Add default features" | npx --yes chalk-cli --stdin green
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/stubs/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
    split("/")[-1] | split(":")[0]')
fi

# If 'upd' argument is provided, set stubs and features to update all features
if [ -n "$upd" ]; then
    echo "Update features" | npx --yes chalk-cli --stdin green
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key|
    split("/")[-1] | split(":")[0]')
fi

# If 'stubs' argument is provided, indicate that stubs are selected
if [ -n "$stubs" ]; then
    echo "Stubs selected" | npx --yes chalk-cli --stdin green
fi

# If 'package' argument is provided, use the specified package.json file
if [ -n "$package" ]; then
    file="$package"
    if [ ! -f "$file" ]; then
        echo "$file not found" | npx --yes chalk-cli --stdin red
        exit
    fi

    echo "Using $file" | npx --yes chalk-cli --stdin green

    # Extract features from the package.json file if not already set
    if [ -z "$features" ]; then
        features=$(cat $file | jq -r '.devcontainer.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| split("/")[-1] | split(":")[0]')
    fi
fi

# If no features are selected, display an error message
if [ -z "$features" ]; then
    echo "No features selected" | npx --yes chalk-cli --stdin red
else
    echo "Selected features: $features" | npx --yes chalk-cli --stdin green
fi

# Merge all files from the stub folder to the root using git merge-file if stubs are selected
if [ -n "$stubs" ]; then
    ./src/common-utils/_install-stubs.sh -s . -t . || exit
fi

# If features are selected, proceed with installation
if [ -n "$features" ]; then

    # Create an alias for the _install-feature.sh script
    alias install-feature=$(dirname $0)/src/common-utils/_install-feature.sh

    # Check if the script is running inside a container
    if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ]; then

        echo "You are not in a container" | npx --yes chalk-cli --stdin green

        # Run the install.sh script for each selected feature
        for feature in $features; do
            if [ -f "$source/src/$feature/install.sh" ]; then
                echo "Running src/$feature/install.sh..." | npx --yes chalk-cli --stdin blue
                bash $source/src/$feature/install.sh -t /tmp
            else
                echo "$feature not found" | npx --yes chalk-cli --stdin red
            fi
        done

        # Run the configure.sh script for each selected feature
        for feature in $features; do
            if [ -f "/tmp/src/$feature/configure.sh" ]; then
                echo "Running src/$feature/configure.sh..." | npx --yes chalk-cli --stdin blue
                bash /tmp/$feature/configure.sh
            else
                echo "$feature not found" | npx --yes chalk-cli --stdin red
            fi
        done
    else
        # If inside a container, suggest using devutils as devcontainer features
        echo "You are in a container: use devutils as devcontainer features:" | npx --yes chalk-cli --stdin magenta
        for feature in $features; do
            echo "ghcr.io/tomgrv/devcontainer-features/$feature"
        done | npx --yes chalk-cli --stdin magenta
        exit
    fi
fi
