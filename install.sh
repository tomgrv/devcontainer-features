#!/bin/sh

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

# Source the common utils
. $source/src/common-utils/_zz_colors.sh

alias zz_log=$source/src/common-utils/_zz_log.sh

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

# Extract tomgrv/devcontainer-features dependencies from a feature's devcontainer-feature.json
feature_deps() {
    _manifest="$source/src/$1/devcontainer-feature.json"
    [ -f "$_manifest" ] || return 0
    jq -r '.dependsOn // {} | to_entries[] |
        select(.key | contains("tomgrv/devcontainer-features")) |
        .key | split("/")[-1] | split(":")[0]' "$_manifest" 2>/dev/null
}

# Expand a whitespace-separated feature list to include all transitive tomgrv/devcontainer-features
# dependencies, ordered so dependencies appear before the features that need them.
resolve_feature_deps() {
    # Step 1: collect the full set of reachable features (original + all transitive deps)
    _all=""
    _queue="$1"
    while [ -n "$_queue" ]; do
        _next=""
        for _f in $_queue; do
            case " $_all " in
            *" $_f "*) continue ;;
            esac
            _all="$_all $_f"
            for _dep in $(feature_deps "$_f"); do
                case " $_all $_next " in
                *" $_dep "*) ;;
                *) _next="$_next $_dep" ;;
                esac
            done
        done
        _queue="$_next"
    done

    # Step 2: topological sort — repeatedly emit features whose tomgrv deps are all emitted
    _emitted=""
    _pending="$_all"
    _changed=1
    while [ "$_changed" = "1" ] && [ -n "$_pending" ]; do
        _changed=0
        _still_pending=""
        for _f in $_pending; do
            _deps_ok=1
            for _dep in $(feature_deps "$_f"); do
                case " $_emitted " in
                *" $_dep "*) ;;
                *)
                    _deps_ok=0
                    break
                    ;;
                esac
            done
            if [ "$_deps_ok" = "1" ]; then
                _emitted="$_emitted $_f"
                _changed=1
            else
                _still_pending="$_still_pending $_f"
            fi
        done
        _pending="$_still_pending"
    done
    # Append any remaining features (handles cycles or missing manifests)
    _emitted="$_emitted $_pending"

    echo "$_emitted" | tr ' ' '\n' | grep -v '^$'
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

# Expand feature list with transitive tomgrv/devcontainer-features dependencies
# from each feature's devcontainer-feature.json, ordered deps-first
if [ -n "$features" ]; then
    features=$(resolve_feature_deps "$features" | tr '\n' ' ')
fi

# Merge all files from the stub folder to the root using git merge-file if stubs are selected
if [ -n "$stubs" ]; then
    echo "${Yellow}Installing stubs from ${UYellow}$source/src/common-utils/${Yellow}...${End}"
    $source/src/common-utils/_configure-feature.sh -s $source .
    echo "${Green}Stubs installed${End}"
fi

# If features are selected, proceed with installation
if [ -n "$features" ]; then

    echo "${Green}Selected features: $features${End}"

    # Create an alias for the _install-feature.sh script
    alias install-feature=$(dirname $0)/src/common-utils/_install-feature.sh

    # Check if the script is running inside a container
    if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ] && [ -z "$DEV_CONTAINER_FILE_PATH" ]; then

        echo "${Red}You are not in a container${End}"

        # Run the install.sh script for each selected feature
        for feature in $features; do
            if [ -f "$source/src/$feature/install.sh" ]; then
                echo "${Yellow}Running src/$feature/install.sh...${End}"
                if sh $source/src/$feature/install.sh; then
                    echo "${Green}$feature installed${End}"
                else
                    echo "${Red}$feature installation failed${End}"
                    exit 1
                fi
            else
                echo "${Red}$feature not found${End}"
                exit 1
            fi
        done

        # Run the configure.sh script for each selected feature
        for feature in $features; do
            featureSource=""
            if [ -d "/tmp/$feature" ]; then
                featureSource="/tmp/$feature"
            elif [ -d "/usr/local/share/$feature" ]; then
                featureSource="/usr/local/share/$feature"
            fi

            if [ -n "$featureSource" ]; then
                echo "${Yellow}Configuring $featureSource...${End}"
                sh $source/src/common-utils/_configure-feature.sh -s $featureSource $feature
                echo "${Green}$feature configured${End}"
            else
                echo "${Red}$feature not found${End}"
                exit 1
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
        echo "${Purple}You are in a container: use as devcontainer features:${End}"
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
