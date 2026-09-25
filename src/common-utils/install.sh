#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

# Resolve this script's directory as an absolute path, regardless of whether
# $0 was invoked relatively (cd src/common-utils && sh install.sh) or with an
# already-absolute path (sh "$source/src/common-utils/install.sh", as used by
# install-feat.sh / npx)
dir=$(dirname $(readlink -f $0))

### Bootstrap the shared zz_* core + this feature's functional scripts from
### https://github.com/tomgrv/scripts — the scripts formerly kept in bin/
### here now live there, shared across every tomgrv repo. Idempotent: a
### zz_use already on PATH (from a previous install) is reused as-is, and
### zz_use itself only fetches/installs whatever isn't already present.
if ! command -v zz_use >/dev/null 2>&1; then
    if ! curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" | sh -; then
        echo "[zz-setup] failed to download the scripts bootstrap" >&2
        exit 1
    fi
fi

zz_use load-json validate-json normalize-json merge-json resolve-context \
    distribute-utils edit-script install-feature configure-feature run-workspace-tests

### Compatibility shims: the rest of this monorepo still calls these by
### their pre-split names (several features' install-*.sh scripts call
### `zz_context`) — install thin
### wrappers over the renamed tomgrv/scripts commands into the same
### writable bin dir zz_use just installed everything else to, so they're
### resolvable system-wide for as long as those other features need them,
### not just for the remainder of this install.
# zz_bindir's own eval output sets a var literally named "dir" — capture it
# under a different name so it doesn't clobber this script's own $dir
# (its source directory, used below and by the rest of this monorepo's
# install.sh convention).
command -v zz_bindir >/dev/null 2>&1 || {
    echo "install.sh: zz_bindir not found on PATH after zz_use" >&2
    exit 1
}
eval "$(zz_bindir)"
bindir="$dir"
dir=$(dirname $(readlink -f $0))

for old_new in zz_context:resolve-context zz_dist:distribute-utils zz_edit:edit-script zz_json:load-json; do
    old=${old_new%%:*}
    new=${old_new#*:}
    target=$(command -v "$new") || {
        echo "install.sh: '$new' not found on PATH after zz_use (needed for the '$old' shim)" >&2
        exit 1
    }
    ln -sf "$target" "$bindir/$old"
done



### Run Installers
install-feature -s $dir
