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
        zz_log s "Updated VERSION file to: $version"
    else
        zz_log w "Could not determine version"
    fi
}

# Function to extract semver from git describe
extract_semver_from_describe() {
    local describe_output="$1"
    # Extract version from tags ending with a semantic version, e.g.:
    # feature_larasets_5.10.2-1-g97bdb34 -> 5.10.2-1-g97bdb34
    # release_5.10.2 -> 5.10.2
    # v5.10.2 -> 5.10.2
    # The regex matches any tag ending with X.Y.Z (optionally with suffixes).
    echo "$describe_output" | sed -E 's/.*[_v]([0-9]+\.[0-9]+\.[0-9]+([-a-zA-Z0-9\.]*)?)/\1/' | head -1
}

# Try GitVersion first (if available and working)
if command -v dotnet-gitversion >/dev/null 2>&1; then
    # Try to get MajorMinorPatch from GitVersion
    GITVERSION_OUTPUT=$(dotnet-gitversion -config .gitversion -showvariable MajorMinorPatch 2>/dev/null || echo "")
    # Check if output is a valid version number (only digits and dots) and not default
    if [ -n "$GITVERSION_OUTPUT" ] && echo "$GITVERSION_OUTPUT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
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
    zz_log w "Could not determine new version, keeping existing VERSION file"
else
    update_version_file "1.0.0"
fi