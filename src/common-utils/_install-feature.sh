#!/bin/sh

# Source colors script
. zz_colors

# Source the context script to initialize variables and settings
eval $(
    zz_context "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-feature <feature>${End}"
    exit 1
fi

zz_log i "Installing feature {Purple $feature}..."

# Copy stubs to the target directory
if [ -d $source/stubs ]; then
    zz_log i "Copying stubs to {U $target}..."
    mkdir -p $target/stubs && cp -r $source/stubs/* $target/stubs
else
    zz_log w "No stubs found in {U $source}"
fi

# Install specific utils by copying them to the target directory and making them executable
find $source \( -name "_*" -o -name "configure-*.sh" -o -path "stubs" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

# Call all the install-xxx scripts in the feature directory
find $source -type f -name "install-*.sh" | while read script; do
    zz_log i "Calling {U $script}..."
    sh -c "$script $@" && zz_log s "Done!" || zz_log e "Failed!"
done
