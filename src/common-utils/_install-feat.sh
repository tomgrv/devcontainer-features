#!/bin/sh

# Installs a single devcontainer feature and its tomgrv/devcontainer-features dependencies.
# Uses install.sh as the orchestrator for recursive dependency installation.
# A tracker file (INSTALL_FEAT_TRACKER) prevents re-installation within the same session.
#
# Usage: install-feat <source_dir> <feature> [--stubs]

_source="$1"
_feature="$2"
_stubs="${3:-}"

if [ -z "$_source" ] || [ -z "$_feature" ]; then
    echo "Usage: install-feat <source_dir> <feature> [--stubs]" >&2
    exit 1
fi

# Prevent re-installation within the same install session
_tracker="${INSTALL_FEAT_TRACKER:-/tmp/.install-feat-$$}"
export INSTALL_FEAT_TRACKER="$_tracker"

if grep -qxF "$_feature" "$_tracker" 2>/dev/null; then
    exit 0
fi
echo "$_feature" >>"$_tracker"

# Install each dependency first, using install.sh as orchestrator (recursive)
for _dep in $(install-deps "$_source" "$_feature"); do
    [ "$_dep" = "$_feature" ] && continue
    if [ -n "$_stubs" ]; then
        sh "$_source/install.sh" -s "$_dep"
    else
        sh "$_source/install.sh" "$_dep"
    fi
done

# Check if the script is running inside a container
if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ] && [ -z "$DEV_CONTAINER_FILE_PATH" ]; then

    # Install the feature itself
    if [ -f "$_source/src/$_feature/install.sh" ]; then
        sh "$_source/src/$_feature/install.sh" || exit 1
    else
        echo "Feature $_feature not found in $_source/src/" >&2
        exit 1
    fi

    # Configure the feature after installation
    _featureSource=""
    if [ -d "/tmp/$_feature" ]; then
        _featureSource="/tmp/$_feature"
    elif [ -d "/usr/local/share/$_feature" ]; then
        _featureSource="/usr/local/share/$_feature"
    fi

    if [ -n "$_featureSource" ]; then
        sh "$_source/src/common-utils/_configure-feature.sh" -s "$_featureSource" "$_feature"
    else
        echo "Feature $_feature installation target not found" >&2
        exit 1
    fi

elif [ -n "$_stubs" ]; then

    # In container with stubs: deploy stubs for this feature
    sh "$_source/src/common-utils/_configure-feature.sh" -s "$_source/src/$_feature" "$_feature"

else

    # Inside a container without stubs: suggest using as devcontainer feature
    echo "You are in a container: use as devcontainer feature: ghcr.io/tomgrv/devcontainer-features/$_feature"

fi
