#!/bin/sh
set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Persist a key=value pair durably" $0 "$@" <<-help
        f file      file        Upsert KEY=VALUE into this .env-style file
        p name      profile     Export KEY=VALUE from /etc/profile.d/<profile>.sh
        - key       key         Variable name
        - value     value       Variable value
help
)

if [ -z "$key" ]; then
    zz_log e "Usage: zz_persist [-f file] [-p profile] <key> <value>"
    exit 1
fi

case "$key" in
[A-Za-z_][A-Za-z0-9_]*) ;;
*)
    zz_log e "Invalid key name: {Purple $key}"
    exit 1
    ;;
esac

if [ -z "$file" ] && [ -z "$profile" ]; then
    zz_log e "At least one of -f or -p is required"
    exit 1
fi

# Escape for sed replacement (avoid &, \\ and delimiter issues)
escaped_value=$(printf '%s' "${value:-}" | sed -e 's/[\\&|]/\\&/g')

### Upsert KEY=VALUE into a plain env-style file (e.g. .env)
if [ -n "$file" ]; then
    touch "$file"
    if grep -q "^$key=" "$file"; then
        sed -i "s|^$key=.*|$key=$escaped_value|" "$file"
    else
        echo "$key=$value" >>"$file"
    fi
    zz_log i "$key persisted to {U $file}"
fi

### Export KEY=VALUE for future interactive shells via /etc/profile.d
if [ -n "$profile" ]; then
    profile_file="/etc/profile.d/$profile.sh"
    if mkdir -p /etc/profile.d 2>/dev/null && touch "$profile_file" 2>/dev/null; then
        if grep -q "^export $key=" "$profile_file" 2>/dev/null; then
            sed -i "s|^export $key=.*|export $key=$escaped_value|" "$profile_file"
        else
            echo "export $key=$value" >>"$profile_file"
        fi
        zz_log i "$key persisted to {U $profile_file}"
    else
        zz_log w "$key: cannot write {U $profile_file}, skipped"
    fi
fi
