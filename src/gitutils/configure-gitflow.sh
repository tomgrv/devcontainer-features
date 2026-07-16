#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# git-flow itself is installed by install-gitflow.sh at feature install time.
if ! git flow version >/dev/null 2>&1; then
    zz_log e "git-flow is not installed. Run the gitutils feature install step first."
    exit 1
fi

master_branch="${GITFLOW_MASTER_BRANCH:-main}"
develop_branch="${GITFLOW_DEVELOP_BRANCH:-develop}"
feature_prefix="${GITFLOW_FEATURE_PREFIX:-feature/}"
bugfix_prefix="${GITFLOW_BUGFIX_PREFIX:-bugfix/}"
release_prefix="${GITFLOW_RELEASE_PREFIX:-release/}"
hotfix_prefix="${GITFLOW_HOTFIX_PREFIX:-hotfix/}"
support_prefix="${GITFLOW_SUPPORT_PREFIX:-support/}"
versiontag_prefix="${GITFLOW_VERSIONTAG_PREFIX:-v}"

# 'git flow init -f' recomputes the master/develop suggestion from gitflow.branch.*
# (falling back to an existing same-named branch, or these values on a fresh repo).
git config gitflow.branch.master "$master_branch"
git config gitflow.branch.develop "$develop_branch"

# Prefixes are only read from --system/--global config by 'init', so pass them
# explicitly to avoid the (empty) built-in defaults, in particular for the tag prefix.
git stash >/dev/null 2>&1
git flow init -d -f \
    -p "$feature_prefix" -b "$bugfix_prefix" -r "$release_prefix" \
    -x "$hotfix_prefix" -s "$support_prefix" -t "$versiontag_prefix" \
    >/dev/null 2>&1 && zz_log s "git-flow initialized successfully." || zz_log e "Failed to initialize git-flow."
git stash pop >/dev/null 2>&1
