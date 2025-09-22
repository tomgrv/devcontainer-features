#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
  exec >/dev/tty 2>&1
fi

# Check if file changed
isChanged() {
  git diff --name-only HEAD@{1} HEAD | grep "^$1" >/dev/null 2>&1
}

# Check if rebase
isRebase() {
  git rev-parse --git-dir | grep -q 'rebase-merge' || git rev-parse --git-dir | grep -q 'rebase-apply' >/dev/null 2>&1
}

# Check if the current Git command is a rebase
if test "$GIT_COMMAND" = "rebase"; then
  zz_log s "Skip post-checkout hook during rebase."
  exit 0
fi

# Update VERSION file with current GitVersion semver using update-version script in the git hooks directory
git hook run update-version || zz_log w "Failed to update VERSION file"
