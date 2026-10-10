#!/bin/sh

# zz_use the gv/bump-* scripts from https://github.com/tomgrv/scripts —
# formerly kept in this feature's own bin/, now shared across every tomgrv
# repo (the same move gitutils' scripts already made). No zz_use bootstrap
# needed here: this feature depends on common-utils (see
# devcontainer-feature.json's dependsOn), whose own install.sh already put
# zz_use on PATH before install-feature runs this install-*.sh.

### Resolve scripts from the tomgrv/scripts line this release was built against
### (same pin as common-utils), not main. Override with ZZ_ORIGIN_REF.
export ZZ_ORIGIN_REF="${ZZ_ORIGIN_REF:-v0}"

zz_use gv bump-tag bump-changelog bump-version
