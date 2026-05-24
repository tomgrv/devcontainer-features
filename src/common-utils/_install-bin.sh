#!/bin/sh

script_dir=$(dirname "$(readlink -f "$0")")

# Source the context script to initialize variables and settings
eval $(
    "$script_dir/_zz_context.sh" "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-bin <feature>"
    exit 1
fi

"$script_dir/_zz_log.sh" i "Installing bin scripts for {Purple $feature}..."

# Resolve a writable bin directory. Defaults to /usr/local/bin, then falls back to
# ~/.local/bin, then to the first writable directory already in PATH, then to $target/bin.
link_dir=${INSTALL_BIN_DIR:-/usr/local/bin}

if [ ! -d "$link_dir" ]; then
    mkdir -p "$link_dir" 2>/dev/null || true
fi

if [ ! -d "$link_dir" ] || [ ! -w "$link_dir" ]; then
    if [ -n "$HOME" ]; then
        mkdir -p "$HOME/.local/bin" 2>/dev/null || true
        if [ -d "$HOME/.local/bin" ] && [ -w "$HOME/.local/bin" ]; then
            link_dir="$HOME/.local/bin"
        fi
    fi
fi

if [ ! -d "$link_dir" ] || [ ! -w "$link_dir" ]; then
    for dir in $(echo "$PATH" | tr ':' '\n'); do
        if [ -d "$dir" ] && [ -w "$dir" ] && [ "$dir" != "." ] && [ "$dir" != "$PWD" ]; then
            case "$dir" in
            */node_modules/.bin) continue ;;
            esac
            link_dir="$dir"
            break
        fi
    done
fi

if [ ! -d "$link_dir" ] || [ ! -w "$link_dir" ]; then
    mkdir -p "$target/bin" 2>/dev/null || true
    if [ -d "$target/bin" ] && [ -w "$target/bin" ]; then
        link_dir="$target/bin"
    fi
fi

if [ ! -d "$link_dir" ] || [ ! -w "$link_dir" ]; then
    "$script_dir/_zz_log.sh" e "No writable bin directory found"
    exit 1
fi

case ":$PATH:" in
*":$link_dir:"*) ;;
*)
    export PATH="$link_dir:$PATH"
    "$script_dir/_zz_log.sh" w "Added {U $link_dir} to PATH for current install session"
    ;;
esac

# Find all shell scripts in the target directory, make them executable, and create symbolic links in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    # Create a symbolic link in /usr/local/bin with the script name (without the leading underscore and .sh extension)
    link=$link_dir/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link && "$script_dir/_zz_log.sh" s "Linked {U $file} to {U $link}"
done
