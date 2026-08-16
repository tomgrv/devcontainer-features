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
# install-bin.sh/install-feature.sh themselves now live in bin/ and match
# this same name pattern, so this must not recurse into it)
find $source -maxdepth 1 -type f -name "install-*.sh" | while read script; do
    zz_log i "Calling {U $script}..."
    sh -c "$script $@" && zz_log s "Done!" || zz_log e "Failed!"
done
