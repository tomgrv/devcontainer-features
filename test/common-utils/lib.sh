#!/bin/sh
# Shared setup for common-utils tests: symlinks every _*.sh script in the
# feature folder into a scratch bin dir, using the same naming convention as
# _install-bin.sh (strip leading "_" and trailing ".sh"), then puts it on PATH.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
UTILS_DIR="$REPO_ROOT/src/common-utils"
TEST_BIN=$(mktemp -d)
trap 'rm -rf "$TEST_BIN"' EXIT

for file in "$UTILS_DIR"/_*.sh; do
    chmod +x "$file"
    ln -sf "$file" "$TEST_BIN/$(basename "$file" | sed 's/^_//; s/\.sh$//')"
done

export PATH="$TEST_BIN:$PATH"

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
