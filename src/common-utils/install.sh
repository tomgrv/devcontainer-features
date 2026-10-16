#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

# Resolve this script's directory as an absolute path, regardless of whether
# $0 was invoked relatively (cd src/common-utils && sh install.sh) or with an
# already-absolute path (sh "$source/src/common-utils/install.sh", as used by
# install-feat.sh / npx)
dir=$(dirname $(readlink -f $0))

### Bootstrap the shared zz-* core + this feature's functional scripts from
### https://github.com/tomgrv/scripts — the scripts formerly kept in bin/
### here now live there, shared across every tomgrv repo. Idempotent: a
### zz-use already on PATH (from a previous install) is reused as-is, and
### zz-use itself only fetches/installs whatever isn't already present.
### Pinned to the tomgrv/scripts major this release was built against, so a
### later breaking rename on main cannot break installs of this release.
### Exported so every zz-use below resolves from the same ref. Override with ZZ_ORIGIN_REF.
export ZZ_ORIGIN_REF="${ZZ_ORIGIN_REF:-v3}"
if ! command -v zz-use >/dev/null 2>&1; then
    if ! curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/$ZZ_ORIGIN_REF/setup.sh}" | sh -; then
        echo "[zz-setup] failed to download the scripts bootstrap" >&2
        exit 1
    fi
fi

zz-use jq yq
zz-use json "json-*" yaml "yaml-*" feature "feature-*" \
    distribute-utils edit-script ws-test ws-list ws-impacted

### Compatibility shims: the rest of this monorepo still calls these by
### their pre-split names (several features' install-*.sh scripts call
### `zz-context`) — install thin
### wrappers over the renamed tomgrv/scripts commands into the same
### writable bin dir zz-use just installed everything else to, so they're
### resolvable system-wide for as long as those other features need them,
### not just for the remainder of this install.
# zz-bindir's own eval output sets a var literally named "dir" — capture it
# under a different name so it doesn't clobber this script's own $dir
# (its source directory, used below and by the rest of this monorepo's
# install.sh convention).
command -v zz-bindir >/dev/null 2>&1 || {
    echo "install.sh: zz-bindir not found on PATH after zz-use" >&2
    exit 1
}
eval "$(zz-bindir)"
bindir="$dir"
dir=$(dirname $(readlink -f $0))

### yaml-merge needs mikefarah/yq, but zz-use skips yq when any `yq` is on
### PATH (e.g. the distro python one). bindir precedes /usr/bin, so installing
### the pinned release there shadows it. Version read from zz-use's own config.
if ! yq --version 2>&1 | grep -q mikefarah; then
    yq_version=$(jq -r '.yq.version' "$bindir/config/zz-use.json")
    yq_arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v$yq_version/yq_linux_$yq_arch" -o "$bindir/yq" \
        && chmod +x "$bindir/yq" || {
        echo "install.sh: failed to install mikefarah/yq v$yq_version" >&2
        exit 1
    }
fi

for old_new in zz-context:feature-context zz-dist:distribute-utils zz-edit:edit-script zz-json:json-load; do
    old=${old_new%%:*}
    new=${old_new#*:}
    target=$(command -v "$new") || {
        echo "install.sh: '$new' not found on PATH after zz-use (needed for the '$old' shim)" >&2
        exit 1
    }
    ln -sf "$target" "$bindir/$old"
done



### Run Installers
feature-install -s $dir
