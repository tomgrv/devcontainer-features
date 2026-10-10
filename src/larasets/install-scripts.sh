#!/bin/sh

# zz-use this feature's scripts from https://github.com/tomgrv/scripts.
# No zz-use bootstrap needed: this feature depends on common-utils (see
# devcontainer-feature.json's dependsOn), whose own install.sh already put
# zz-use on PATH before install-feature runs this install-*.sh.

### Resolve scripts from the tomgrv/scripts line this release was built against
### (same pin as common-utils), not main. Override with ZZ_ORIGIN_REF.
export ZZ_ORIGIN_REF="${ZZ_ORIGIN_REF:-v1.1}"

zz-use php-list-changed
