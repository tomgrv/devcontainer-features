#!/usr/bin/env bash
# Shared bats setup for common-utils tests: links src/common-utils/bin/*.sh
# onto PATH under their public command names, the same way zz_feature -i does.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

setup_common_utils_path() {
    local feature_dir="$REPO_ROOT/src/common-utils"
    local file
    TEST_BIN=$(mktemp -d)
    for file in "$feature_dir"/bin/*.sh; do
        [ -f "$file" ] || continue
        chmod +x "$file"
        ln -sf "$file" "$TEST_BIN/$(basename "$file" | sed 's/\.sh$//')"
    done
    export PATH="$TEST_BIN:$PATH"
}

teardown_common_utils_path() {
    rm -rf "$TEST_BIN"
}
