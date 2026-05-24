#!/bin/sh

target="${1:-$target}"

candidates=""

add_candidate() {
    candidate="$1"
    [ -n "$candidate" ] || return 0

    case ":$candidates:" in
    *:"$candidate":*) ;;
    *)
        if [ -n "$candidates" ]; then
            candidates="$candidates:$candidate"
        else
            candidates="$candidate"
        fi
        ;;
    esac
}

add_candidate "${INSTALL_BIN_DIR:-/usr/local/bin}"

if [ -n "$HOME" ]; then
    add_candidate "$HOME/.local/bin"
fi

for dir in $(echo "$PATH" | tr ':' '\n'); do
    case "$dir" in
    "" | "." | "$PWD" | */node_modules/.bin) continue ;;
    esac
    add_candidate "$dir"
done

add_candidate "$target/bin"

link_dir=""
old_ifs=$IFS
IFS=':'
for candidate in $candidates; do
    [ -d "$candidate" ] || mkdir -p "$candidate" 2>/dev/null || true
    if [ -d "$candidate" ] && [ -w "$candidate" ]; then
        link_dir="$candidate"
        break
    fi
done
IFS=$old_ifs

[ -n "$link_dir" ] || exit 1

echo "$link_dir"
