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
    curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" | sh
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
eval "$(zz_bindir)"
bindir="$dir"
dir=$(dirname $(readlink -f $0))

for old_new in zz_context:resolve-context zz_dist:distribute-utils zz_edit:edit-script zz_json:load-json; do
    old=${old_new%%:*}
    new=${old_new#*:}
    ln -sf "$(command -v "$new")" "$bindir/$old"
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
