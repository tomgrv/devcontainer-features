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
    # Downloaded to a temp file rather than piped straight into sh: a
    # `curl | sh` pipeline's exit status is sh's, not curl's, so a failed
    # download would otherwise go unnoticed and this script would carry on
    # without zz_use.
    _zz_setup_tmp=$(mktemp) || {
        echo "install.sh: mktemp failed" >&2
        exit 1
    }
    if ! curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" -o "$_zz_setup_tmp"; then
        echo "install.sh: failed to download the zz_use bootstrap" >&2
        rm -f "$_zz_setup_tmp"
        exit 1
    fi
    sh "$_zz_setup_tmp"
    _zz_setup_rc=$?
    rm -f "$_zz_setup_tmp"
    [ "$_zz_setup_rc" -eq 0 ] || exit "$_zz_setup_rc"
fi
export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"

zz_use load-json validate-json normalize-json merge-json resolve-context \
    distribute-utils edit-script install-feature configure-feature

### Compatibility shims: the rest of this monorepo still calls these by
### their pre-split names (every devcontainer-feature.json's
### postCreateCommand runs `zz_feature -c <name>`; several other
### features' install-*.sh scripts call `zz_context`) — install thin
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

cat >"$bindir/zz_feature" <<'SHIM'
#!/bin/sh
# Compatibility shim: this monorepo calls `zz_feature -i`/`-c` everywhere;
# the underlying logic now lives at https://github.com/tomgrv/scripts as
# two separate commands.
case "$1" in
-i) shift; exec install-feature "$@" ;;
-c) shift; exec configure-feature "$@" ;;
*) echo "Usage: zz_feature -i|-c [-s source] [-t target] <arg>" >&2; exit 1 ;;
esac
SHIM
chmod +x "$bindir/zz_feature"

### Install utils
for bin in $UTILS; do

    zz_log i "Checking {B $bin}..."

    if [ -n "$(command -v $bin)" ]; then
        zz_log s "{B $bin} is installed."
    elif [ -f /etc/alpine-release ]; then
        apk update
        apk add $bin
    elif [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
        sudo apt-get update
        sudo apt-get install -y $bin
    elif [ $(uname -o) = "Msys" ]; then
        winget install -s winget -e --name $bin --location /tmp/common-utils
    else
        zz_log w "Please install {B $bin} Manually."
        exit 1
    fi
done >&2

### Run Installers
zz_feature -i -s $dir
