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

# Find all shell scripts in the target directory, make them executable, and create symbolic links in the selected bin directory
find "$target" -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while IFS= read -r file; do
    # Create a symbolic link in the selected bin directory with the script name (without the leading underscore and .sh extension)
    link="$link_dir/$(basename "$file" | sed 's/^_//;s/.sh$//')"
    ln -sf "$file" "$link" && zz_log s "Linked {U $file} to {U $link}"
done
