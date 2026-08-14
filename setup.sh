#!/bin/sh

# Bootstraps tomgrv/devcontainer-features from a single curl command, without
# requiring node/npm/git to already be installed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add -x
#
# Everything after "-s --" is forwarded to install.sh (see: install.sh help).
# With no arguments, install.sh auto-detects features from .devcontainer/*/devcontainer.json.
#
# Override the source ref (branch, tag, or commit) with DEVCONTAINER_FEATURES_REF (default: develop).

set -e

_repo="tomgrv/devcontainer-features"
_ref="${DEVCONTAINER_FEATURES_REF:-develop}"

for _cmd in curl tar; do
    command -v "$_cmd" > /dev/null 2>&1 || {
        echo "setup.sh: '$_cmd' is required" >&2
        exit 1
    }
done

_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT INT TERM

_url="https://codeload.github.com/${_repo}/tar.gz/${_ref}"
_tarball="$_tmp/repo.tar.gz"

echo "setup.sh: fetching ${_repo}@${_ref}..." >&2
curl -fsSL "$_url" -o "$_tarball"
tar --extract --gunzip --strip-components=1 --directory "$_tmp" -f "$_tarball"
rm -f "$_tarball"

sh "$_tmp/install.sh" "$@"
