#!/bin/sh
export PATH=/usr/bin:$PATH
source=$(dirname $(readlink -f $0))

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Check if the current Git command is a rebase
if test "$GIT_COMMAND" = "rebase"; then
    npx --yes chalk-cli --no-stdin -t "{green ✔} Skip pre-commit hook during rebase"
    exit 0
fi

echo $GIT_COMMAND

# Check if the current commit contains package.json changes
if git diff ${@:---cached --name-only} | grep -q "package.json"; then

    # ensure that the package.json is valid and package-lock.json is up-to-date
    npx --yes chalk-cli --no-stdin -t "{blue →}  Ensure that the package.json is valid and package-lock.json is up-to-date..."

    ws=$(npm pkg get workspaces)
    if test "$ws" = "undefined" || test "$ws" = "{}"; then
        npm install --package-lock || true
    else
        npm install --package-lock --ws --if-present --include-workspace-root || true
    fi

    # commit the updated package-lock.json
    git add package-lock.json
fi

# Check if the current commit contains composer.json changes
if git diff ${@:---cached --name-only} | grep -q "composer.json"; then

    # ensure that the composer.json is valid and composer.lock is up-to-date
    npx --yes chalk-cli --no-stdin -t "{blue →}  Ensure that the composer.json is valid and composer.lock is up-to-date..."
    composer validate --no-check-all --strict 2>&1 | grep -oP 'Required package "\K[^"]+' | while read -r package; do
        composer require --ignore-platform-reqs --no-scripts --no-interaction --no-progress --no-install "$package"
    done

    # commit the updated composer.lock
    git add composer.lock
fi

# Install Prettier plugins
npm install --no-save $(cat package.json | npx --yes jqn '.prettier.plugins' | tr -d "'[]:,") 2>/dev/null 1>&2

# Run pre-commit checks
npx --yes git-precommit-checks
npx --yes lint-staged --cwd ${INIT_CWD:-$PWD}
