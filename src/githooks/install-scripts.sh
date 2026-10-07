#!/bin/sh

# zz-use this feature's git-hook-* scripts from https://github.com/tomgrv/scripts.
# No zz-use bootstrap needed: this feature depends on gitutils, which depends
# on common-utils (see devcontainer-feature.json's dependsOn), whose own
# install.sh already put zz-use on PATH before install-feature runs this
# install-*.sh.

zz-use git-hook-commitmsg git-hook-installplugins git-hook-postcheckout \
    git-hook-postmerge git-hook-precommit git-hook-preparecommitmsg \
    git-hook-prepush
