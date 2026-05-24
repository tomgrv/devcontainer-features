#!/bin/sh

# Source the context script to initialize variables and settings
eval $(
    zz_context "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-bin <feature>"
    exit 1
fi

zz_log i "Installing bin scripts for {Purple $feature}..."

link_dir="$(sh "$(dirname "$0")/_select-bin.sh" "$target")"
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

# Find all shell scripts in the target directory, make them executable, and create symbolic links in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    # Create a symbolic link in /usr/local/bin with the script name (without the leading underscore and .sh extension)
    link=$link_dir/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link && zz_log s "Linked {U $file} to {U $link}"
done
