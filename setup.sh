#!/bin/sh

# Bootstraps tomgrv/devcontainer-features from a single curl command, without
# requiring node/npm/git to already be installed: installs zz_use + the
# common zz_* bundle (via tomgrv/scripts), then execs this repo's main
# entrypoint - package.json's "main" field (install.sh), falling back to a
# root main.sh if there's no "main" field, or stopping if neither exists.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add -x
#
# Everything after "-s --" is forwarded to the main entrypoint (install.sh;
# see: install.sh help). With no arguments, install.sh auto-detects features
# from .devcontainer/*/devcontainer.json.
#
# Override the source ref (branch, tag, or commit) with DEVCONTAINER_FEATURES_REF (default: develop).
# Override the zz_use bootstrap ref/URL with ZZ_SCRIPTS_REF / ZZ_SCRIPTS_SETUP_URL.

set -e

_repo="tomgrv/devcontainer-features"
_ref="${DEVCONTAINER_FEATURES_REF:-develop}"

for _cmd in curl tar mktemp; do
    command -v "$_cmd" > /dev/null 2>&1 || {
        echo "setup.sh: '$_cmd' is required" >&2
        exit 1
    }
done

_zz_scripts_ref="${ZZ_SCRIPTS_REF:-main}"
_zz_scripts_setup_url="${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/${_zz_scripts_ref}/setup.sh}"
echo "setup.sh: installing zz_use + common zz_* via tomgrv/scripts..." >&2
curl -fsSL "$_zz_scripts_setup_url" | sh -s -- "$_zz_scripts_ref"

_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT INT TERM
echo "setup.sh: using temp dir ${_tmp}" >&2

_url="https://codeload.github.com/${_repo}/tar.gz/${_ref}"
_tarball="$_tmp/repo.tar.gz"

echo "setup.sh: fetching ${_repo}@${_ref}..." >&2
curl -fsSL "$_url" -o "$_tarball"
echo "setup.sh: extracting $(wc -c < "$_tarball" | tr -d ' ') bytes..." >&2
tar -xzf "$_tarball" --strip-components=1 -C "$_tmp"
rm -f "$_tarball"

_main=$(sed -n 's/^[[:space:]]*"main"[[:space:]]*:[[:space:]]*"\(.*\)"[,]*[[:space:]]*$/\1/p' "$_tmp/package.json" 2>/dev/null | head -n1)
if [ -n "$_main" ] && [ -f "$_tmp/$_main" ]; then
    echo "setup.sh: running ${_main} (package.json \"main\") $*" >&2
    sh "$_tmp/$_main" "$@"
elif [ -f "$_tmp/main.sh" ]; then
    echo "setup.sh: running main.sh $*" >&2
    sh "$_tmp/main.sh" "$@"
else
    echo "setup.sh: no \"main\" field in package.json and no main.sh found; nothing to run." >&2
fi
