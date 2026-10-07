#!/bin/sh

# zz-use this feature's git-* scripts from https://github.com/tomgrv/scripts.
# No zz-use bootstrap needed: this feature depends on common-utils (see
# devcontainer-feature.json's dependsOn), whose own install.sh already put
# zz-use on PATH before install-feature runs this install-*.sh.

zz-use git-align git-autorebase git-co git-degit git-fix git-fix-author \
    git-fix-base git-fix-blanks git-fix-children git-fix-date git-fix-del \
    git-fix-emoji git-fix-last git-fix-lock git-fix-message git-fix-mode \
    git-fix-privacy git-fix-prune git-fix-rights git-fix-secrets git-fix-up \
    git-forall git-getcommit git-integrate git-pick git-release \
    git-release-alpha git-release-beta git-release-hotfix git-release-prod \
    git-unset git-workspaces
