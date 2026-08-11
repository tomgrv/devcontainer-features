#!/bin/sh
# Run every test-*.sh in this folder and fail if any of them fails.
set -e

dir=$(cd "$(dirname "$0")" && pwd)
status=0

for test in "$dir"/test-*.sh; do
    echo "=== $(basename "$test") ==="
    sh "$test" || status=1
    echo ""
done

exit $status
