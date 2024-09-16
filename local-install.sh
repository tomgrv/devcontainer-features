#!/bin/sh

### Go to root
cd $(git rev-parse --show-toplevel) >/dev/null

### Load all features locally installable
features=$(jq -r '.config.local[]' package.json)

### Handles arguments
if [ -n "$1" ]; then
    case $1 in
        --help)
            echo "Usage: $0 [--help] [<feature>]"
            exit 
            ;;
        *)
            echo "Selected features: $*" | npx --yes chalk-cli --stdin blue
            features=$*
            ;;
    esac
fi

### Stash all changes including untracked files
stash=$(git stash -u && echo true)

### Ask to restart in container if this is not already the case
if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ]; then
    echo "You are not in a container" | npx --yes chalk-cli --stdin green

    ### Call the install.sh script in all selected features
    for feature in $features; do
        if [ -f "./src/$feature/install.sh" ]; then
            ### Run the install.sh script
            echo "Running src/$feature/install.sh..." | npx --yes chalk-cli --stdin blue
            bash ./src/$feature/install.sh /tmp 
        else
            echo "$feature not found" | npx --yes chalk-cli --stdin red
        fi
    done

    ### Call the configure.sh script in all selected features
    for feature in $features; do
        if [ -f "./src/$feature/configure.sh" ]; then
            ### Run the install.sh script
            echo "Running src/$feature/configure.sh..." | npx --yes chalk-cli --stdin blue
            bash /tmp/$feature/configure.sh
        else
            echo "$feature not found" | npx --yes chalk-cli --stdin red
        fi
    done
else
    echo "You are in a container: use devutils as devcontainer features:" | npx --yes chalk-cli --stdin magenta
    for feature in $features; do
        echo "ghcr.io/tomgrv/devcontainer-features/$feature" 
    done | npx --yes chalk-cli --stdin magenta
    exit
fi

### Stage non withespace changes
git ls-files --others --exclude-standard | xargs -I {} bash -c 'if [ -s "{}" ]; then git add "{}"; fi'
git diff -w --no-color | git apply --cached --ignore-whitespace
git checkout -- . && git reset && git add .

### Unstash changes
test -n "$stash" && git stash apply && git stash drop