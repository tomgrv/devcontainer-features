<!-- @format -->

# Test Structure

Tests are organized per feature in the `test/` directory, using [bats-core](https://github.com/bats-core/bats-core). Each feature has its own subfolder with a shared `helpers.bash` and one `.bats` file per unit of behavior being tested.

## Adding Tests for a New Feature

1. Create a feature test folder: `test/<feature-name>/`

2. Create a `helpers.bash` in the folder that links the feature's `_*.sh` scripts onto `PATH` under their public command names, the same way `install-bin` does:

```bash
#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup_<feature-name>_path() {
    local feature_dir="$REPO_ROOT/src/<feature-name>"
    local file
    TEST_BIN=$(mktemp -d)
    for file in "$feature_dir"/_*.sh; do
        [ -f "$file" ] || continue
        chmod +x "$file"
        ln -sf "$file" "$TEST_BIN/$(basename "$file" | sed 's/^_//; s/\.sh$//')"
    done
    export PATH="$TEST_BIN:$PATH"
}

teardown_<feature-name>_path() {
    rm -rf "$TEST_BIN"
}
```

3. Create test files with `test-*.bats` naming, `load helpers`, and use bats' `setup()`/`teardown()` hooks plus `$BATS_TEST_TMPDIR` for scratch files:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    setup_<feature-name>_path
}

teardown() {
    teardown_<feature-name>_path
}

@test "test label" {
    result="$(some-command)"
    [ "$result" = "expected" ]
}
```

4. No runner script is needed — bats globs `test-*.bats` files in a directory natively: `bats test/<feature-name>/`.

5. Add a CI workflow at `.github/workflows/test-<feature-name>.yaml` that runs `bats test/<feature-name>/` — see `test-common-utils.yaml` for an example. All workflows that run code tests follow the `test-<scope>.yaml` naming convention.

## Common Test Utilities

`bats` provides `run` (captures `$status`/`$output` from a command or function without needing manual subshell/exit-status juggling) and a fresh `$BATS_TEST_TMPDIR` per test (auto-cleaned) in place of hand-rolled `mktemp -d`/`trap EXIT` scratch dirs.

## Example

See `test/common-utils/` for a working example, including `test-args.bats` for the `run`-based pattern used to test usage/exit-code behavior.
