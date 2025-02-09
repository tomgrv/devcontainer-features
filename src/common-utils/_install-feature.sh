#!/bin/sh

# Source the context script to initialize variables and settings
. zz_context "$@"

echo "Installing feature <$feature>..."

# Install specific utils by copying them to the target directory and making them executable
find $source \( -name "_*" -o -name "configure-*.sh" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

# Call all the install-xxx scripts in the feature directory
echo "Calling all install scripts in $source..."
find $source -type f -name "install-*.sh" | while read script; do
    echo "Calling $script..."
    sh $script
done
