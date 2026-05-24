#!/bin/sh

script_dir=$(dirname "$(readlink -f "$0")")

# Source colors script
. "$script_dir/_zz_colors.sh"

# Source the context script to initialize variables and settings
eval $(
    "$script_dir/_zz_context.sh" "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-feature <feature>${End}"
    exit 1
fi

"$script_dir/_zz_log.sh" i "Installing feature {Purple $feature}..."

# Copy stubs to the target directory
if [ -d $source/stubs ]; then
    "$script_dir/_zz_log.sh" i "Copying stubs to {U $target}..."
    cp -a $source/stubs $target
else
    "$script_dir/_zz_log.sh" w "No stubs found in {U $source}"
fi

# Install specific utils by copying them to the target directory and making them executable
find $source \( -name "_*" -o -name "configure-*.sh" -o -path "stubs" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

# Call all the install-xxx scripts in the feature directory
find $source -type f -name "install-*.sh" | while read script; do
"$script_dir/_zz_log.sh" i "Calling {U $script}..."
sh -c "$script $@" && "$script_dir/_zz_log.sh" s "Done!" || "$script_dir/_zz_log.sh" e "Failed!"
done
