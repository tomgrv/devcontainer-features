#!/bin/sh

#### Go to root directory
cd "$(git rev-parse --show-toplevel)"

### Stash all changes including untracked files
git stash -u

#### Get commit to fixup
sha=$(git getcommit "$@")

#### Check if fixup commit is valid
if [ -z "$sha" ]; then
    echo "No commit to fixup"
    exit 1
fi

#### Display commit to fixup
echo "Fixing commit: $sha"

### Redo all composer.lock files
git filter-branch --tree-filter '
    composer validate --no-check-all --strict 2>&1 | grep -oP "Required package \"\K[^\"]+" | while read -r package; do
        composer require --ignore-platform-reqs --no-scripts --no-interaction --no-progress --no-install "$package"
    done;
    npm install --ws --package-lock-only;
    git add $(find . -name "composer.lock") $(find . -name "package-lock.json") || true
' $sha..HEAD

### Unstash changes
git stash pop

#### Back to previous directory
cd - >/dev/null
