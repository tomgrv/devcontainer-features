<!-- @format -->

# Test Structure

Tests are organized per feature in the `test/` directory. Each feature has its own subfolder with test files and a `lib.sh` that sources common test utilities.

## Adding Tests for a New Feature

1. Create a feature test folder: `test/<feature-name>/`

2. Create a `lib.sh` in the folder:

```bash
#!/bin/sh
# Test setup for <feature-name> feature.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
. "$REPO_ROOT/test/lib.sh"

setup_feature_utils <feature-name>
```

3. Create test files with `test-*.sh` naming and source `lib.sh`:

```bash
#!/bin/sh
set -e

. "$(dirname "$0")/lib.sh"

# Use assert_eq, assert_status, and report functions
assert_eq "test label" "expected" "actual"
report
```

4. Create a `run.sh` to execute all tests:

```bash
#!/bin/sh
set -e

dir=$(cd "$(dirname "$0")" && pwd)
status=0

for test in "$dir"/test-*.sh; do
    echo "=== $(basename "$test") ==="
    sh "$test" || status=1
    echo ""
done

exit $status
```

## Common Test Utilities

Available in `test/lib.sh`:

- `assert_eq <label> <expected> <actual>` — Assert values are equal
- `assert_status <label> <expected-exit-code> <actual-exit-code>` — Assert exit codes match
- `report` — Print test summary and exit with proper status
- `setup_feature_utils <feature-name>` — Link feature utility scripts to PATH

## Example

See `test/common-utils/` for a working example.
