#!/bin/sh

### Go to root
cd $(git rev-parse --show-toplevel) >/dev/null

### Add common utils to path
export PATH=$PATH:$(dirname $0)/src/common-utils

### Load all features locally installable
source=$(dirname $(readlink -f $0))

### Load arguments
. _zz-args.sh "Install features locally" $0 "$@" <<-help
    a -         all         Install all features
    u -         upd         Update all features
    s -         stubs       Install stubs only
    p -         package     Specify package.json file to use
    + features  features    List of features to install
help

if [ -n "$all" ]; then
    echo "Add default features" | npx --yes chalk-cli --stdin green
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/stubs/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
    split("/")[-1] | split(":")[0]')
fi

if [ -n "$upd" ]; then
    echo "Update features" | npx --yes chalk-cli --stdin green
    stubs=1
    features=$(sed '/^\s*\/\//d' $source/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key|
    split("/")[-1] | split(":")[0]')
fi

if [ -n "$stubs" ]; then
    echo "Stubs selected" | npx --yes chalk-cli --stdin green
fi

if [ -n "$package" ]; then
    file="$package"
    if [ ! -f "$file" ]; then
        echo "$file not found" | npx --yes chalk-cli --stdin red
        exit
    fi

    echo "Using $file" | npx --yes chalk-cli --stdin green

    if [ -z "$features" ]; then
        features=$(cat $file | jq -r '.devcontainer.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| split("/")[-1] | split(":")[0]')
    fi
fi

if [ -z "$features" ]; then
    echo "No features selected" | npx --yes chalk-cli --stdin red
else
    echo "Selected features: $features" | npx --yes chalk-cli --stdin green
fi

### Stash all changes including untracked files
stash=$(git stash -u && echo true)

### Force line endings to LF for all text files
echo "Force line endings to LF for all text files" | npx --yes chalk-cli --stdin blue
git ls-files -z | xargs -0 rm
git checkout .

### Merge all files from stub folder to root with git merge-file
if [ -n "$stubs" ]; then
    ./src/common-utils/_install-stubs.sh -s . -t . || exit
fi

if [ -n "$features" ]; then
    ### Ask eventualy to deploy in container if this is not already the case
    if [ "$CODESPACES" != "true" ] && [ "$REMOTE_CONTAINERS" != "true" ]; then

        echo "You are not in a container" | npx --yes chalk-cli --stdin green

        ### Call the install.sh script in all selected features
        for feature in $features; do
            if [ -f "$source/src/$feature/install.sh" ]; then
                ### Run the install.sh script
                echo "Running src/$feature/install.sh..." | npx --yes chalk-cli --stdin blue
                bash $source/src/$feature/install.sh /tmp
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
fi

### Stage non withespace changes
git ls-files --others --exclude-standard | xargs -I {} bash -c 'if [ -s "{}" ]; then git add "{}"; fi'
git diff -w --no-color | git apply --cached --ignore-whitespace --allow-empty
git checkout -- . && git reset && git add .

### Unstash changes
test -n "$stash" && git stash apply && git stash drop
