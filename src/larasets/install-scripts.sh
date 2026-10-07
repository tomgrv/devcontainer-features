#!/bin/sh

# zz-use this feature's scripts from https://github.com/tomgrv/scripts.
# No zz-use bootstrap needed: this feature depends on common-utils (see
# devcontainer-feature.json's dependsOn), whose own install.sh already put
# zz-use on PATH before feature-install runs this install-*.sh.

zz-use php-list-changed
