#!/bin/sh

### Go to root
cd $(git rev-parse --show-toplevel) >/dev/null

### Load all features locally installable
source=$(dirname $(readlink -f $0))
features=""
stubs="0"

### Handles arguments
while getopts ":hausp:" opt $@; do
    case $opt in
    h)
        echo "Usage: $0 [-h|-a|-u|-s|-p file|<features>]"
        echo "  -h: Display this help"
        echo "  -a: All features"
        echo "  -s: Stubs only"
        echo "  -p: Specify package.json file to use"
        echo -n "  <features>: List of features to install. Available features: "
        cat package.json | npx --yes jqn '.config.local' | tr -d "'[]:," | npx --yes chalk-cli --stdin blue
        exit
        ;;
    a)
        echo "Add default features" | npx --yes chalk-cli --stdin green
        stubs=1
        features=$(sed '/^\s*\/\//d' $source/stubs/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
 split("/")[-1] | split(":")[0]')
        break
        ;;
    u)
        echo "Update features" | npx --yes chalk-cli --stdin green
        stubs=1
        features=$(sed '/^\s*\/\//d' $source/.devcontainer/devcontainer.json | jq -r '.features | to_entries[] | select(.key | contains("tomgrv/devcontainer-features"))| .key| 
split("/")[-1] | split(":")[0]')
        break
        ;;
    s)
        echo "Stubs selected" | npx --yes chalk-cli --stdin green
        stubs=1
        ;;
    p)
        file="$OPTARG"
        if [ ! -f "$file" ]; then
            echo "$file not found" | npx --yes chalk-cli --stdin red
            exit
        fi
        ;;
    \?)
        echo "Invalid option: -$OPTARG" | npx --yes chalk-cli --stdin red
        exit
        ;;
    :)
        echo "Option -$OPTARG requires an argument." | npx --yes chalk-cli --stdin red
        exit
        ;;
    esac
done >&2

# Shift off the options and optional --
shift $((OPTIND - 1))

# Handle remaining arguments as features
if [ $# -gt 0 ]; then
    features="$@"
    if [ -f "$file" ]; then
        pkg=$(cat $file | npx --yes jqn $features | tr -d "'[]:,")
        for package in $pkg; do
            npm list $package 2>/dev/null 1>&2 || npm install --no-save $package 2>/dev/null 1>&2 && echo "Installed $package" | npx --yes chalk-cli --stdin green || echo "Failed to install $package" | npx --yes chalk-cli --stdin red
        done
        exit
    else
        echo "Selected features: $features" | npx --yes chalk-cli --stdin green
    fi
fi

### Stash all changes including untracked files
stash=$(git stash -u && echo true)

### Force line endings to LF for all text files
echo "Force line endings to LF for all text files" | npx --yes chalk-cli --stdin blue
git ls-files -z | xargs -0 rm
git checkout .

### Merge all files from stub folder to root with git merge-file
if [ "$stubs" -eq "1" ]; then
    ./src/common-utils/_install-stubs.sh . . || exit
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
