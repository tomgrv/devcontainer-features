#!/bin/bash

# Source colors script
. zz_colors

# Source the context script to initialize variables and settings
eval $(
    zz_context "$@"
)

if [ -z "$feature" ]; then
    echo -e "Usage: install-feature <feature>\r"
    exit 1
fi

echo -e "Installing feature <${Purple}$feature${None}>...\r"

# Copy stubs to the target directory
if [ -d $source/stubs ]; then
    echo -e "${Blue}Copying stubs to '$target'...${End}"
    mkdir -p $target/stubs && cp -r $source/stubs/* $target/stubs
else
    echo -e "${Yellow}No stubs found in '$source'${End}"
fi

# Install specific utils by copying them to the target directory and making them executable
find $source \( -name "_*" -o -name "configure-*.sh" -o -path "stubs" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

# Call all the install-xxx scripts in the feature directory
echo -e "${Blue}Calling all install scripts in '$source'...${End}"
find $source -type f -name "install-*.sh" | while read script; do
    echo -e "${Yellow}Calling $script...${End}"
    sh $script "$@"
    echo -e "${Green}Done!${End}"
done
