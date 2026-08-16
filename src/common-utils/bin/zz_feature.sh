#!/bin/sh

# Source colors script
. zz_colors

# Source the argument parsing script to handle input arguments
eval $(
    zz_args "Install or configure a feature" $0 "$@" <<-help
    i -         install     Install mode: copy stubs/config/bin into target, run install-*.sh
    c -         configure   Configure mode: deploy stubs into the current directory, run configure-*.sh
    s source    source      Force source directory
    t target    target      Force target directory (install mode only)
    - arg       arg         Install mode: caller script path. Configure mode: feature name
help
)

if [ -n "$install" ] && [ -n "$configure" ]; then
    zz_log e "Choose one of -i (install) or -c (configure), not both"
    exit 1
fi

if [ -n "$install" ]; then

    ### Install mode ###

    # Rebuild a clean argument list before delegating to zz_context: our own
    # "$@" still holds the raw -i/-s/... invocation (zz_args doesn't touch
    # the caller's "$@"), and this same list gets forwarded to every
    # install-*.sh script below. Several of those (e.g. gateway's
    # install-wrapper.sh) re-parse "$@" themselves via zz_context, whose spec
    # has no -i flag — a stray -i would break its getopts loop early and
    # silently corrupt source/target resolution downstream.
    set -- ${source:+-s "$source"} ${target:+-t "$target"} ${arg:+"$arg"}

    # Source the context script to initialize variables and settings
    eval $(
        zz_context "$@"
    )

    if [ -z "$feature" ]; then
        echo "Usage: zz_feature -i <caller>${End}"
        exit 1
    fi

    zz_log i "Installing feature {Purple $feature}..."

    # Copy stubs to the target directory
    if [ -d $source/stubs ]; then
        zz_log i "Copying stubs to {U $target}..."
        cp -a $source/stubs $target
    else
        zz_log w "No stubs found in {U $source}"
    fi

    # Copy config to the target directory
    if [ -d $source/config ]; then
        zz_log i "Copying config to {U $target}..."
        cp -a $source/config $target
    fi

    # Copy bin scripts to the target directory, preserving the bin/ subdirectory
    if [ -d $source/bin ]; then
        zz_log i "Copying bin scripts to {U $target}..."
        cp -a $source/bin $target
    fi

    # Install lifecycle scripts by copying them to the target directory and making them executable
    find $source -maxdepth 1 -name "configure-*.sh" -type f -exec cp {} $target \;
    find $target -type f -name "*.sh" -exec chmod +x {} \;

    # Call all the install-xxx scripts in the feature directory (root only —
    # zz_feature.sh/install-bin.sh themselves now live in bin/ and match this
    # same name pattern only if literally named install-*.sh, which they
    # aren't, but -maxdepth 1 keeps this scoped to root lifecycle scripts)
    find $source -maxdepth 1 -type f -name "install-*.sh" | while read script; do
        zz_log i "Calling {U $script}..."
        # sh -c "$script $@" mis-forwards a multi-element "$@" here: "$@"
        # embedded mid-string in a larger double-quoted word only glues its
        # first element onto that word, so sh -c only ever sees the option
        # letter of the first flag as the whole command's arguments — silent
        # until "$@" holds more than one element (which -s/-t forwarding now
        # does). Invoke via `sh "$script" "$@"` instead, which forwards
        # positional parameters correctly regardless of count.
        sh "$script" "$@" && zz_log s "Done!" || zz_log e "Failed!"
    done

elif [ -n "$configure" ]; then

    ### Configure mode ###

    feature=$arg

    if [ -z "$feature" ]; then
        echo "Usage: zz_feature -c <feature>${End}"
        exit 1
    fi

    # Initialize the source directory based on the feature name
    export source=${source:-/usr/local/share/$feature}

    # Get the indent size from devcontainer.json with jq, default to 2 if not found
    export tabSize=4

    zz_log i "Configure feature <{Purple $feature}>"
    zz_log - "In {U $(pwd)}"
    zz_log - "From {U $source}"

    # Ensure the source directory exists
    if [ ! -d $source ]; then
        zz_log e "Source directory <$source> does not exist"
        exit 1
    fi

    # Deploy stubs if existing
    if [ -d $source/stubs ]; then

        zz_log i "Deploying stubs..."

        find $source/stubs -type f -name ".*" -o -type f | sort | while read file; do

            # Get the relative of the path
            folder=$(dirname ${file#$source/stubs/})

            # Get the destination file basename. A basename starting with "_" marks
            # a qualifier segment (the part up to the first ".") to be stripped, so
            # several distinctly-named fragments (_foo.package.json, _bar.package.json)
            # can all resolve to and accumulate into the same target (package.json).
            base=$(basename $file | sed 's/\.\./\./g')
            case "$base" in
            _*)
                base=${base#_}
                base=${base#*.}
                ;;
            esac

            # Get the destination file path
            dest=$folder/$base

            # Create the folder if it does not exist
            mkdir -p $folder

            # if filename starts with #, add it to .gitignore without the #
            if [ "$(basename $file | cut -c1)" = "#" ]; then

                # Remove # occurrences in the file path
                dest=$(echo $dest | sed 's/\/\#/\//g')

                # Add to .gitignore if not already there
                zz_log - "Add {U $dest} to .gitignore"

                # Add to .gitignore if not already there
                grep -qxF $dest .gitignore || echo "$dest" >>.gitignore
            fi

            # Use git merge-file to merge the file
            if [ -f $dest ]; then

                # if json file, use merge-json to merge the file
                if [ "${dest##*.}" = "json" ]; then
                    zz_log - "Merging {U $file} into {U $dest}..."
                    merge-json -t ${tabSize:-4} $dest $file
                else
                    zz_log - "Using git merge-file to merge {U $file} into {U $dest}..."
                    git merge-file -q $dest $file $file
                fi

            else
                zz_log w "Destination file {U $dest} does not exist. Copying {U $file} to {U $dest}..."
                cp $file $dest
            fi

            # Apply the same permissions as the original file
            chmod $(stat -c "%a" $file) $dest

        done

        zz_log i "Deploying stubs symlinks if existing..."

        # Deploy stubs symlinks if existing
        find "$source/stubs" -type l | while IFS= read -r link; do
            rel=${link#"$source/stubs/"}
            dest=$rel
            mkdir -p "$(dirname "$dest")"
            if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
                target=$(readlink "$link")
                zz_log - "Creating symlink {U $dest} -> {U $target}..."
                ln -s "$target" "$dest"
            fi
        done

        zz_log s "Done deploying stubs."
    fi

    # if in top level directory, call configure scripts
    if [ "$(pwd)" = "$(git rev-parse --show-toplevel)" ]; then

        zz_log i "Checking for configure scripts in the source directory..."

        # Call all configure-xxx.sh scripts
        find $source -maxdepth 1 -name configure-*.sh | sort | while read file; do
            zz_log - "Calling {U $file}..."
            sh -c "$file" && zz_log s "Done!" || zz_log e "Failed!"
        done
    else
        zz_log w "Not in top level directory, skipping configure scripts"
    fi

else
    echo "Usage: zz_feature -i|-c [-s source] [-t target] <arg>${End}"
    exit 1
fi
