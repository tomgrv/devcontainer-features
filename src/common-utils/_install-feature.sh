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

echo "Installing feature <${Purple}$feature${None}>...${End}"

# Copy stubs to the target directory
if [ -d $source/stubs ]; then
    echo "${Blue}Copying stubs to '$target'...${End}"
    mkdir -p $target/stubs && cp -r $source/stubs/* $target/stubs
else
    echo "${Yellow}No stubs found in '$source'${End}"
fi

# Install specific utils by copying them to the target directory and making them executable
find $source \( -name "_*" -o -name "configure-*.sh" -o -path "stubs" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

# Call all the install-xxx scripts in the feature directory
echo "${Blue}Calling all install scripts in '$source'...${End}"
find $source -type f -name "install-*.sh" | while read script; do
    echo "${Yellow}Calling $script...${End}"
    sh -c "$script $@"
    echo "${Green}Done!${End}"
done
