#!/bin/sh

#### GOTO DIRECTORY
cd "$(git rev-parse --show-toplevel)"

set_permissions() {
    local type="$1"
    local name="$2"
    local perm="$3"
    echo "Setting permissions $perm for typer <$type> with name pattern '$name'"
    git ls-files -o -i --exclude-standard | grep -v '/$' | xargs -I {} find "{}" -type "$type" -name "$name" -exec chmod "$perm" {} \;
}

# Set default permissions for directories
set_permissions d "*" 755

# Set default permissions for regular files
set_permissions f "*" 644

# Set permissions for executable files (e.g., scripts)
set_permissions f "*.sh" 755

# Set permissions for sensitive files (e.g., configuration files)
set_permissions f "*.conf" 600
set_permissions f "*.env" 600

# Set permissions for specific directories (e.g., logs, cache)
set_permissions d "logs" 700
set_permissions d "cache" 700

echo "Access rights have been set according to best practices."
