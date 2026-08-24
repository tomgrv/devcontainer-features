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
    # zz_feature.sh itself now lives in bin/ and matches this same name
    # pattern only if literally named install-*.sh, which it isn't, but
    # -maxdepth 1 keeps this scoped to root lifecycle scripts)
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

    ### Symlink bin/ scripts onto a writable PATH directory (formerly a
    ### separate install-bin command) — $target/$feature are already
    ### resolved above, and $target's *.sh files are already chmod +x'd.

    zz_log i "Installing bin scripts for {Purple $feature}..."

    # Function to add a candidate directory to the list of candidates and optionally mark it as creatable
    add_candidate() {
        candidate="$1"
        can_create="${2:-0}"
        [ -n "$candidate" ] || return 0

        case ":$candidates:" in
        *":$candidate:"*) ;;
        *)
            if [ -n "$candidates" ]; then
                candidates="$candidates:$candidate"
            else
                candidates="$candidate"
            fi
            if [ "$can_create" = "1" ]; then
                if [ -n "$creatable" ]; then
                    creatable="$creatable:$candidate"
                else
                    creatable="$candidate"
                fi
            fi
            ;;
        esac
    }

    # Initialize empty strings for candidates and creatable directories
    zz_log i "Finding writable bin directory..."
    candidates=""
    creatable=""

    # Add default candidates for the bin directory
    add_candidate "${INSTALL_BIN_DIR:-/usr/local/bin}" 1
    if [ -n "$HOME" ]; then
        add_candidate "$HOME/.local/bin" 1
    fi

    # Add directories from the PATH environment variable as candidates, excluding certain directories
    old_ifs=$IFS
    IFS=':'
    for dir in $PATH; do
        case "$dir" in
        "" | "." | "$PWD" | */node_modules/.bin) continue ;;
        esac
        add_candidate "$dir"
    done
    IFS=$old_ifs
    add_candidate "$target/bin" 1

    # Find a writable bin directory from the candidates or creatable directories
    link_dir=""
    old_ifs=$IFS
    IFS=':'
    for candidate in $candidates; do
        if [ -d "$candidate" ] && [ -w "$candidate" ] && [ -x "$candidate" ]; then
            link_dir="$candidate"
            break
        fi
    done

    # If no writable directory was found, try to create one from the creatable candidates
    if [ -z "$link_dir" ]; then
        for candidate in $creatable; do
            mkdir -p "$candidate" 2>/dev/null || true
            if [ -d "$candidate" ] && [ -w "$candidate" ] && [ -x "$candidate" ]; then
                link_dir="$candidate"
                break
            fi
        done
    fi
    IFS=$old_ifs

    # Check if a writable bin directory was found, and exit with an error if not
    [ -n "$link_dir" ] || {
        zz_log e "No writable bin directory found"
        exit 1
    }

    case ":$PATH:" in
    *":$link_dir:"*) ;;
    *)
        export PATH="$link_dir:$PATH"
        zz_log w "Added {U $link_dir} to PATH for current install session"
        ;;
    esac

    # Find all shell scripts in the feature's bin/ directory and create symbolic links in the selected bin directory
    find "$target/bin" -type f -name "*.sh" 2>/dev/null | while IFS= read -r file; do
        # Create a symbolic link in the selected bin directory with the script name (without the .sh extension)
        link="$link_dir/$(basename "$file" | sed 's/.sh$//')"
        ln -sf "$file" "$link" && zz_log s "Linked {U $file} to {U $link}"
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

            # Deploy the file into dest, merging with whatever is already there
            if [ "${dest##*.}" = "json" ]; then

                # JSON fragments accumulate via merge-json's own recursive merge
                if [ -f $dest ]; then
                    zz_log - "Merging {U $file} into {U $dest}..."
                    merge-json -t ${tabSize:-4} $dest $file
                else
                    zz_log w "Destination file {U $dest} does not exist. Copying {U $file} to {U $dest}..."
                    cp $file $dest
                fi

            else
                # Non-JSON fragments accumulate via a plain line-set
                # reconciliation, not git merge-file: merge-file's 3-way
                # diff is positional, and independent fragments routinely
                # add their distinct lines at the very same spot (end of
                # the shared common lines), which it reports as a
                # conflict it can't order rather than two additions to
                # union. Keep a per-(feature, fragment) snapshot of what
                # was last deployed and diff the incoming file against it:
                # lines the snapshot had that the incoming file no longer
                # does were genuinely dropped upstream and get removed
                # from dest; lines the incoming file has that the snapshot
                # didn't get appended if dest doesn't already have them
                # (from this or any other fragment). No snapshot yet (the
                # very first deploy of this fragment, or the first fragment
                # ever deployed to this dest) behaves the same way with an
                # empty base: nothing to remove, everything to add. Dates
                # gate the attempt Make-style: skip entirely once this
                # exact source file hasn't changed since it was captured.
                snapshot_dir=$(git rev-parse --git-path info 2>/dev/null || echo .git/info)/zz_feature/state
                snapshot=$snapshot_dir/$(echo -n "$feature/${file#$source/stubs/}" | sha1sum | cut -d' ' -f1)
                mkdir -p $snapshot_dir
                base=$snapshot
                [ -f $base ] || base=/dev/null

                if [ ! -f $dest ]; then
                    zz_log w "Destination file {U $dest} does not exist. Copying {U $file} to {U $dest}..."
                    cp $file $dest
                elif [ $base != /dev/null ] && [ ! $file -nt $base ]; then
                    zz_log - "No change in {U $file} since last deploy, skipping merge into {U $dest}"
                else
                    zz_log - "Reconciling {U $file} into {U $dest}..."

                    removed=$(mktemp)
                    grep -vFxf $file $base >$removed
                    if [ -s $removed ]; then
                        reconciled=$(mktemp)
                        grep -vFxf $removed $dest >$reconciled
                        cat $reconciled >$dest
                        rm -f $reconciled
                    fi
                    rm -f $removed

                    added=$(mktemp)
                    grep -vFxf $base $file >$added
                    if [ -s $added ]; then
                        new=$(mktemp)
                        grep -vFxf $dest $added >$new
                        if [ -s $new ]; then
                            [ -z "$(tail -c1 $dest)" ] || printf '\n' >>$dest
                            cat $new >>$dest
                        fi
                        rm -f $new
                    fi
                    rm -f $added
                fi

                cp -p $file $snapshot
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
