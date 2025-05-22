#!/bin/sh

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

# Source the common utils
. $source/src/common-utils/_zz_colors.sh

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
    echo "${Yellow}Add default features${End}"
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/stubs/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
    split("/")[-1] | split(":")[0]')
fi

# If 'upd' argument is provided, set stubs and features to update all features
if [ -n "$upd" ]; then
    echo "${Green}Update features${End}"
    stubs=1
    features=$(
        sed '/^\s*\/\//d' .devcontainer/devcontainer.json |
            jq -r '.features | to_entries[] |
                    select(.key | contains("tomgrv/devcontainer-features")) |
                    .key | 
                    split("/")[-1] |
                    split(":")[0]' |
            tr '\n' ' '
    )
fi

# If 'stubs' argument is provided, indicate that stubs are selected
if [ -n "$stubs" ]; then
    echo "${Green}Stubs selected${End}"
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
        features=$(cat $file | jq -r '.devcontainer.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| split("/")[-1] | split(":")[0]')
    fi
fi

# If no features are selected, display an error message
if [ -z "$features" ]; then
    echo "${Red}No features selected${End}"
else
    echo "${Green}Selected features: $features${End}"
fi

# Merge all files from the stub folder to the root using git merge-file if stubs are selected
if [ -n "$stubs" ]; then
    echo "${Yellow}Installing stubs...${End}"
    $source/src/common-utils/_configure-feature.sh -s $source .
    echo "${Green}Stubs installed${End}"
fi

# If features are selected, proceed with installation
if [ -n "$features" ]; then

    # Create an alias for the _install-feature.sh script
    alias install-feature=$(dirname $0)/src/common-utils/_install-feature.sh

    # Check if the script is running inside a container
    if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ]; then

        echo "${Red}You are not in a container${End}"

        # Run the install.sh script for each selected feature
        for feature in $features; do
            if [ -f "$source/src/$feature/install.sh" ]; then
                echo "${Yellow}Running src/$feature/install.sh...${End}"
                sh $source/src/$feature/install.sh
                echo "${Green}$feature installed${End}"
            else
                echo "${Red}$feature not found${End}"
            fi
        done

        # Run the configure.sh script for each selected feature
        for feature in $features; do
            if [ -d "/tmp/$feature" ]; then
                echo "${Yellow}Configuring /tmp/$feature...${End}"
                sh $source/src/common-utils/_configure-feature.sh -s /tmp/$feature $feature
                echo "${Green}$feature configured${End}"
            else
                echo "${Red}$feature not found${End}"
            fi
        done

    elif [ -n "$stubs" ]; then

        # stubs are selected, configure stubs of the selected features
        for feature in $features; do
            echo "${Yellow}Deploying stubs for $feature...${End}"
            $source/src/common-utils/_configure-feature.sh -s $source/src/$feature $feature
            echo "${Green}Stubs for $feature deployed${End}"
        done

    else
        # If inside a container, suggest using devutils as devcontainer features
        echo "${Purple}You are in a container: use devutils as devcontainer features:${End}"
        for feature in $features; do
            echo "${Purple}ghcr.io/tomgrv/devcontainer-features/$feature${End}"
        done

    fi
fi

# Remoce all links to common utils
echo "Remove temp files..."
find $source/src/common-utils/ -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    rm $source/src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//')
done
