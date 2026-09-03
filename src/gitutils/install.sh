#!/bin/sh

### Resolve this script's directory as an absolute path, regardless of
### whether $0 was invoked relatively or with an already-absolute path
dir=$(dirname $(readlink -f $0))

### Bootstrap the shared zz_* core + this feature's git-* scripts from
### https://github.com/tomgrv/scripts — the scripts formerly kept in bin/
### here now live there, shared across every tomgrv repo (the same move
### common-utils' install.sh already made). Idempotent: a zz_use already
### on PATH (from common-utils installing first, per this feature's own
### dependsOn) is reused as-is; zz_use itself only fetches/installs
### whatever isn't already present.
if ! command -v zz_use > /dev/null 2>&1; then
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

zz_use git-align git-autorebase git-co git-degit git-fix git-fix-author \
    git-fix-base git-fix-blanks git-fix-children git-fix-date git-fix-del \
    git-fix-emoji git-fix-last git-fix-lock git-fix-message git-fix-mode \
    git-fix-privacy git-fix-prune git-fix-rights git-fix-secrets git-fix-up \
    git-forall git-getcommit git-integrate git-pick git-release \
    git-release-alpha git-release-beta git-release-hotfix git-release-prod \
    git-unset git-workspaces

### Run this feature's own installers: git-flow (install-gitflow.sh),
### alias/config wiring (install-config.sh), and stubs/config deployment —
### there's no bin/ left here for it to copy, the git-* scripts above cover
### that now.
zz_feature -i -s $dir
