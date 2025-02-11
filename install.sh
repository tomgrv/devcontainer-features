#!/bin/sh

# Go to the root directory of the original script
cd $(git rev-parse --show-toplevel)

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

# Source the common utils
. $source/src/common-utils/_*.env

# Prepare for local installation by creating a temporary directory and linking common utils
find $source/src/common-utils/ -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    ln -sf $file $source/src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//')
done
export PATH=$PATH:$source/src/common-utils

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

# If 'all' argument is provided, set stubs and features to install all default features
if [ -n "$all" ]; then
    echo "${Yellow}Add default features${None}"
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/stubs/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
    split("/")[-1] | split(":")[0]')
fi

# If 'upd' argument is provided, set stubs and features to update all features
if [ -n "$upd" ]; then
    echo "${Green}Update features${None}"
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key|
    split("/")[-1] | split(":")[0]')
fi

# If 'stubs' argument is provided, indicate that stubs are selected
if [ -n "$stubs" ]; then
    echo "${Green}Stubs selected${None}"
fi

# If 'package' argument is provided, use the specified package.json file
if [ -n "$package" ]; then
    file="$package"
    if [ ! -f "$file" ]; then
        echo "${Red}File not found: $file${None}"
        exit
    fi

    echo "${Green}Using $file${None}"

    # Extract features from the package.json file if not already set
    if [ -z "$features" ]; then
        features=$(cat $file | jq -r '.devcontainer.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| split("/")[-1] | split(":")[0]')
    fi
fi

# If no features are selected, display an error message
if [ -z "$features" ]; then
    echo "${Red}No features selected${None}"
else
    echo "${Green}Selected features: $features${None}"
fi

# Merge all files from the stub folder to the root using git merge-file if stubs are selected
if [ -n "$stubs" ]; then
    echo "${Yellow}Installing stubs...${None}"
    $source/src/common-utils/_install-stubs.sh -s $source -t . || exit 1
    echo "${Green}Stubs installed${None}"
fi

# If features are selected, proceed with installation
if [ -n "$features" ]; then

    # Create an alias for the _install-feature.sh script
    alias install-feature=$(dirname $0)/src/common-utils/_install-feature.sh

    # Check if the script is running inside a container
    if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ]; then

        echo "${Red}You are not in a container${None}"

        # Run the install.sh script for each selected feature
        for feature in $features; do
            if [ -f "$source/src/$feature/install.sh" ]; then
                echo "${Yellow}Running src/$feature/install.sh...${None}"
                sh $source/src/$feature/install.sh -t /tmp
                echo "${Green}$feature installed${None}"
            else
                echo "${Red}$feature not found${None}"
            fi
        done

        # Run the configure.sh script for each selected feature
        for feature in $features; do
            if [ -f "/tmp/src/$feature/configure.sh" ]; then
                echo "${Yellow}Running src/$feature/configure.sh...${None}"
                sh /tmp/$feature/configure.sh
                echo "${Green}$feature configured${None}"
            else
                echo "${Red}$feature not found${None}"
            fi
        done
    else
        # If inside a container, suggest using devutils as devcontainer features
        echo "${Purple}You are in a container: use devutils as devcontainer features:${None}"
        for feature in $features; do
            echo "${Purple}ghcr.io/tomgrv/devcontainer-features/$feature${None}"
        done
        exit
    fi
fi
