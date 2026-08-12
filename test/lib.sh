#!/bin/sh
# Common test utilities for all features.
# Provides assertion functions and helpers for setting up feature tests.

set -e

pass=0
fail=0

assert_eq() {
    label=$1
    expected=$2
    actual=$3

    if [ "$expected" = "$actual" ]; then
        pass=$((pass + 1))
        echo "ok - $label"
    else
        fail=$((fail + 1))
        echo "not ok - $label"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_status() {
    label=$1
    expected_status=$2
    actual_status=$3

    if [ "$expected_status" = "$actual_status" ]; then
        pass=$((pass + 1))
        echo "ok - $label"
    else
        fail=$((fail + 1))
        echo "not ok - $label (expected exit $expected_status, got $actual_status)"
    fi
}

report() {
    echo ""
    echo "$pass passed, $fail failed"
    [ "$fail" -eq 0 ]
}

# Setup utility scripts from a feature directory.
# Usage: setup_feature_utils <feature-name>
# Links all _*.sh scripts from src/<feature-name>/ into a temporary bin directory
# and adds it to PATH.
# Note: REPO_ROOT should be set in the calling script before sourcing this lib.
setup_feature_utils() {
    feature=$1
    if [ -z "$feature" ]; then
        echo "Error: feature name required for setup_feature_utils" >&2
        return 1
    fi

    if [ -z "$REPO_ROOT" ]; then
        echo "Error: REPO_ROOT environment variable must be set" >&2
        return 1
    fi

    FEATURE_DIR="$REPO_ROOT/src/$feature"
    TEST_BIN=$(mktemp -d)
    trap 'rm -rf "$TEST_BIN"' EXIT

    if [ ! -d "$FEATURE_DIR" ]; then
        echo "Error: feature directory not found: $FEATURE_DIR" >&2
        return 1
    fi

    for file in "$FEATURE_DIR"/_*.sh; do
        if [ -f "$file" ]; then
            chmod +x "$file"
            ln -sf "$file" "$TEST_BIN/$(basename "$file" | sed 's/^_//; s/\.sh$//')"
        fi
    done

    export PATH="$TEST_BIN:$PATH"
}
