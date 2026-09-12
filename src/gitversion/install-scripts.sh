#!/bin/sh

# zz_use the gv/bump-* scripts from https://github.com/tomgrv/scripts —
# formerly kept in this feature's own bin/, now shared across every tomgrv
# repo (the same move gitutils' scripts already made). No zz_use bootstrap
# needed here: this feature depends on common-utils (see
# devcontainer-feature.json's dependsOn), whose own install.sh already put
# zz_use on PATH before install-feature runs this install-*.sh.

zz_use gv bump-tag bump-changelog bump-version
