#!/usr/bin/env bats
# @format

# Guards against installers resolving tomgrv/scripts from `main`. A rename
# there breaks every release that bootstraps from it: v8 failed with
# `zz_use: not found`, v9 with `resolve-context` not found. Bootstraps must
# fetch setup.sh from $ZZ_ORIGIN_REF, which the same file defaults to a
# versioned ref (see UPGRADING.md §0).

setup() {
  ROOT="${BATS_TEST_DIRNAME}/.."
  # Shell sources that run at install/hook time. Excludes docs, tests,
  # node_modules, and src/scripting/stubs/setup.sh (a consumer-facing
  # entrypoint with its own ZZ_SCRIPTS_REF option).
  FILES=$(grep -rlE 'tomgrv/scripts/|zz-use ' "$ROOT" \
    --include='*.sh' --include='pre-commit' --include='commit-msg' \
    --include='post-checkout' --include='post-merge' --include='pre-push' \
    --include='prepare-commit-msg' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tests \
    --exclude-dir=_ | grep -v 'src/scripting/stubs/setup.sh' || true)
}

@test "no bootstrap downloads tomgrv/scripts setup.sh from main" {
  offenders=$(echo "$FILES" | xargs -r grep -nE 'tomgrv/scripts/main/setup\.sh' || true)

  if [ -n "$offenders" ]; then
    echo "Pin the ref (\$ZZ_ORIGIN_REF) instead of main:"
    echo "$offenders"
    return 1
  fi
}

@test "files fetching setup.sh from \$ZZ_ORIGIN_REF default it to a versioned ref" {
  for f in $(echo "$FILES" | xargs -r grep -lE 'scripts/\$ZZ_ORIGIN_REF/setup\.sh'); do
    grep -qE 'ZZ_ORIGIN_REF:-v[0-9]+' "$f" || {
      echo "$f uses \$ZZ_ORIGIN_REF but does not default it to a versioned ref (vN)"
      return 1
    }
  done
}

@test "files calling zz-use outside the bootstrap default ZZ_ORIGIN_REF too" {
  for f in $(echo "$FILES" | xargs -r grep -lE '^\s*zz-use '); do
    grep -qE 'ZZ_ORIGIN_REF:-v[0-9]+' "$f" || {
      echo "$f calls zz-use without defaulting ZZ_ORIGIN_REF to a versioned ref"
      return 1
    }
  done
}
