#!/bin/sh

target="${1:-$target}"

candidates=""
creatable=""

add_candidate() {
    candidate="$1"
    can_create="${2:-0}"
    [ -n "$candidate" ] || return 0

    case ":$candidates:" in
    *:"$candidate":*) ;;
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

add_candidate "${INSTALL_BIN_DIR:-/usr/local/bin}" 1

if [ -n "$HOME" ]; then
    add_candidate "$HOME/.local/bin" 1
fi

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

link_dir=""
old_ifs=$IFS
IFS=':'

# First pass: find an existing writable and executable directory
for candidate in $candidates; do
    if [ -d "$candidate" ] && [ -w "$candidate" ] && [ -x "$candidate" ]; then
        link_dir="$candidate"
        break
    fi
done

# Second pass: try to create known/safe directories if none found yet
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

[ -n "$link_dir" ] || exit 1

echo "$link_dir"
