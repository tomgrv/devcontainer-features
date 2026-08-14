#!/bin/sh

# Installs a single devcontainer feature and its tomgrv/devcontainer-features dependencies.
# Uses install.sh as the orchestrator for recursive dependency installation.
# A tracker file (INSTALL_FEAT_TRACKER) prevents re-installation within the same session.
#
# Usage: install-feat <source_dir> <feature>

_source="$1"
_feature="$2"

if [ -z "$_source" ] || [ -z "$_feature" ]; then
    echo "Usage: install-feat <source_dir> <feature>" >&2
    exit 1
fi

# Prevent re-installation within the same install session
_tracker="${INSTALL_FEAT_TRACKER:-/tmp/.install-feat-$$}"
export INSTALL_FEAT_TRACKER="$_tracker"

if grep -qxF "$_feature" "$_tracker" 2>/dev/null; then
    exit 0
fi
echo "$_feature" >>"$_tracker"

_stub_count=$(find "$_source/src/$_feature/stubs" \( -type f -o -type l \) 2>/dev/null | wc -l | tr -d ' ')
zz_log i "Deploying {Purple $_feature} (${_stub_count} stub(s))..."

# Install each dependency first, using install.sh as orchestrator (recursive)
for _dep in $(sh "$_source/install-deps.sh" "$_source" "$_feature"); do
    [ "$_dep" = "$_feature" ] && continue
    sh "$_source/install.sh" add "$_dep"
done

# Install the feature itself (host or container: install-*.sh scripts that
# genuinely need to tell the two apart already do so internally, e.g.
# gateway/install-wrapper.sh checks REMOTE_CONTAINERS/CODESPACES itself to
# decide whether to divert the system curl).
if [ -f "$_source/src/$_feature/install.sh" ]; then
    sh "$_source/src/$_feature/install.sh" || exit 1
else
    echo "Feature $_feature not found in $_source/src/" >&2
    exit 1
fi

# Configure the feature after installation, from wherever install-feature
# copied it to (its target dir, resolved the same way for host and
# container: writable candidates first, /tmp/<feature> as a fallback).
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
