#!/bin/sh

# Determine PATH & source
export PATH=/usr/bin:$PATH
source=$(dirname $(readlink -f $0))

# Enable colors
if [ -t 1 ]; then
    exec >/dev/tty 2>&1
fi

# Check if the current Git command is a rebase
if test "$GIT_COMMAND" = "rebase"; then
    zz_log s "Skip pre-commit hook during rebase"
    exit 0
fi

zz_log i "Git command: {Cyan $GIT_COMMAND}"

# Check if the current commit contains package.json changes
if git diff --name-only ${@:---cached } | grep -q "package.json"; then

    # ensure that the package.json is valid and package-lock.json is up-to-date
    zz_log i "Ensure that the package.json is valid and package-lock.json is up-to-date..."

    ws=$(npm pkg get workspaces)
    if test "$ws" = "undefined" || test "$ws" = "{}"; then
        npm install --package-lock || true
    else
        npm install --package-lock --ws --if-present --include-workspace-root || true
    fi

    # commit the updated package-lock.json if file changed
    if git diff --quiet package-lock.json; then
        zz_log s "package-lock.json update not required"
    else
        git add package-lock.json && zz_log w "Updated package-lock.json"
    fi
fi

# Check if the current commit contains composer.json changes
if git diff --name-only ${@:---cached} | grep -q "composer.json"; then

    # ensure that the composer.json is valid and composer.lock is up-to-date
    zz_log i "Ensure that the composer.json is valid and composer.lock is up-to-date..."
    composer validate --no-check-all --strict 2>&1 | grep -oP 'Required package "\K[^"]+' | while read -r package; do
        composer require --ignore-platform-reqs --with-all-dependencies --no-scripts --no-interaction --no-progress --no-install "$package"
    done

    # Update composer.lock
    composer validate --no-check-all --strict || composer update --lock --minimal-changes --ignore-platform-reqs --with-all-dependencies --no-scripts --no-interaction --no-progress --no-install

    # commit the updated composer.lock if file changed
    if git diff --quiet composer.lock; then
        zz_log s "composer.lock update not required"
    else
        git add composer.lock && zz_log w "Updated composer.lock"
    fi
fi

# Install Prettier plugins if they are not already installed
git hook run install-plugins -- '.prettier.plugins//""'

# Run pre-commit checks
npx --yes git-precommit-checks
npx --yes lint-staged --cwd ${INIT_CWD:-$PWD} --allow-empty
