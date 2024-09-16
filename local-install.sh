#!/bin/sh

### Go to root
cd $(git rev-parse --show-toplevel) >/dev/null

### Load all features locally installable
features=""
stubs="0"

### Handles arguments
if [ -n "$1" ]; then

    case $1 in
        --help)
            echo "Usage: $0 [--help|--stubs|--all|<features>]"
            exit 
            ;;
        --all|--start)
            echo "All selected" | npx --yes chalk-cli --stdin green
            stubs=1
            features=$(jq -r '.config.local[]' package.json)
            break;
            ;;
        --stubs)
            echo "Stubs selected" | npx --yes chalk-cli --stdin green
            stubs=1
            ;;
        --*)
            echo "Wrong arguments: See --help" | npx --yes chalk-cli --stdin red
            exit
            ;;
        *)
            echo "Features selected: $*" | npx --yes chalk-cli --stdin green
            features=$*
            ;;
    esac
fi

### Stash all changes including untracked files
stash=$(git stash -u && echo true)

if [ "$stubs" -eq "1" ]; then

    ### Merge all files from stub folder to root with git merge-file
    echo "Merging stubs files" | npx --yes chalk-cli --stdin blue
    for file in $(find ./stubs -type f); do

        ### Get middle part of the path
        folder=$(dirname ${file#./stubs/})

        ### Create folder if not exists
        mkdir -p $folder

        ### Merge file
        echo "Merge $folder/$(basename $file)" | npx --yes chalk-cli --stdin yellow
        git merge-file -p $file $folder/$(basename $file) ${folder#./}/$(basename $file) > $folder/$(basename $file)

        ### Apply rights
        chmod $(stat -c "%a" $file) $folder/$(basename $file)
    done

    ### Find all file with a trailing slash outside dist folder, make sure they are added to .gitignore and remove the trailing slash
    echo "Add files to .gitignore" | npx --yes chalk-cli --stdin blue
    for file in $(find . -type f -name "#*" -not -path "./stubs/*" -not -path "./node_modules/*" -not -path "./vendors/*"); do

        echo "Add $file to .gitignore" | npx --yes chalk-cli --stdin yellow

        ### Remove trailing # and leading ./#
        clean=${file#./#}

        ### Add to .gitignore if not already there
        grep -qxF $clean .gitignore || echo "$clean" >>.gitignore

        ### Rename file
        mv $file $clean
    done
fi

if [ -n "$features" ]; then
    ### Ask eventualy to deploy in container if this is not already the case
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
fi

### Stage non withespace changes
git ls-files --others --exclude-standard | xargs -I {} bash -c 'if [ -s "{}" ]; then git add "{}"; fi'
git diff -w --no-color | git apply --cached --ignore-whitespace --allow-empty
git checkout -- . && git reset && git add .

### Unstash changes
test -n "$stash" && git stash apply && git stash drop

### Start script
if [ "$1" = "--start" ]; then
    ./.devcontainer/start.sh
fi