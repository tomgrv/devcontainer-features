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
  npx chalk-cli --no-stdin -t "{green ✔} Skip post-checkout hook during rebase."
  exit 0
fi
