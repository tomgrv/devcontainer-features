#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Check if the current Git command is a rebase
if test "$GIT_COMMAND" = "rebase"; then
    npx chalk-cli --no-stdin -t "{green ✔} Skip pre-commit hook during rebase"
    exit 0
fi

# Check if the current commit contains package.json changes
if git diff --cached --name-only | grep -q "package.json"; then

    # ensure that the package.json is valid and package-lock.json is up-to-date
    WORKSP=$(cat package.json | npx jqn '.workspaces' | tr -d "'[]:")
    if test "$WORKSP" = "undefined"; then
        npm install || true
    else
        npm install --ws --if-present --include-workspace-root || true
    fi

    # commit the updated package-lock.json
    git add package-lock.json
fi

# Check if the current commit contains composer.json changes
if git diff --cached --name-only | grep -q "composer.json"; then

    # ensure that the composer.json is valid and composer.lock is up-to-date
    composer validate --no-check-publish || true
    composer update --no-interaction --no-progress --no-suggest --no-dev || true

    # commit the updated composer.lock
    git add composer.lock
fi

npx git-precommit-checks
npx lint-staged --cwd ${INIT_CWD:-$PWD}
