#!/bin/bash
# Script to update VERSION file with GitVersion semver
# This script handles both GitVersion tool and fallback scenarios

set -e

# Define the VERSION file path
VERSION_FILE="VERSION"

# Function to update VERSION file
update_version_file() {
    local version="$1"
    if [ -n "$version" ]; then
        echo "$version" > "$VERSION_FILE"
        echo "Updated VERSION file to: $version"
    else
        echo "Warning: Could not determine version"
    fi
}

# Function to extract semver from git describe
extract_semver_from_describe() {
    local describe_output="$1"
    # Extract version from patterns like:
    # feature_larasets_5.10.2-1-g97bdb34 -> 5.10.2-1-g97bdb34
    # feature_larasets_5.10.2 -> 5.10.2
    echo "$describe_output" | sed -E 's/^[^_]*_[^_]*_([0-9]+\.[0-9]+\.[0-9]+.*)/\1/' | head -1
}

# Try GitVersion first (if available and working)
if command -v dotnet-gitversion >/dev/null 2>&1; then
    # Try to get MajorMinorPatch from GitVersion
    GITVERSION_OUTPUT=$(dotnet-gitversion -config .gitversion -showvariable MajorMinorPatch 2>/dev/null || echo "")
    # Check if output is a valid version number (only digits and dots) and not default
    if [ -n "$GITVERSION_OUTPUT" ] && echo "$GITVERSION_OUTPUT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && [ "$GITVERSION_OUTPUT" != "1.0.0" ]; then
        update_version_file "$GITVERSION_OUTPUT"
        exit 0
    fi
fi

# Fallback to git describe
GIT_DESCRIBE=$(git describe --tags --always --dirty 2>/dev/null || echo "")
if [ -n "$GIT_DESCRIBE" ]; then
    FALLBACK_VERSION=$(extract_semver_from_describe "$GIT_DESCRIBE")
    update_version_file "$FALLBACK_VERSION"
    exit 0
fi

# Final fallback - keep existing version or use default
if [ -f "$VERSION_FILE" ]; then
    echo "Warning: Could not determine new version, keeping existing VERSION file"
else
    update_version_file "1.0.0"
fi