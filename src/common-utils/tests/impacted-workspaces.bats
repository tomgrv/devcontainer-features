#!/usr/bin/env bats
# @format

# The draft-PR scoping script deployed with test-workspaces.yaml: from the
# changed files it prints the list-packages `filter` for the impacted workspaces.

SCRIPT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)/stubs/.github/scripts/impacted-workspaces.sh"

setup() {
  export WORKDIR="$BATS_TEST_TMPDIR"
  mkdir -p "$WORKDIR"/{lib,app,tool}
  echo '{"workspaces":["lib","app","tool"],"name":"root"}' >"$WORKDIR/package.json"
  echo '{"name":"@x/lib"}' >"$WORKDIR/lib/package.json"
  echo '{"name":"@x/app","peerDependencies":{"@x/lib":"*"}}' >"$WORKDIR/app/package.json"
  echo '{"name":"@x/tool","devDependencies":{"@x/app":"*"}}' >"$WORKDIR/tool/package.json"
}

impacted() { printf '%s\n' "$@" | "$SCRIPT"; }

@test "a changed workspace is impacted together with its transitive dependents" {
  run impacted lib/run.sh
  [ "$status" -eq 0 ]
  [ "$output" = '(.location | IN("lib","app","tool"))' ]
}

@test "a leaf workspace impacts only itself" {
  run impacted tool/test.bats
  [ "$status" -eq 0 ]
  [ "$output" = '(.location | IN("tool"))' ]
}

@test "a middle workspace impacts itself and its dependents, not its dependencies" {
  run impacted app/run.sh
  [ "$output" = '(.location | IN("app","tool"))' ]
}

@test "a file owned by no workspace impacts everybody (empty filter)" {
  run impacted tool/run.sh .github/workflows/x.yml
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Markdown impacts nobody: only-docs changes give a filter that keeps nothing" {
  run impacted README.md lib/README.md
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "Markdown beside a code change does not widen the scope" {
  run impacted tool/run.sh README.md
  [ "$output" = '(.location | IN("tool"))' ]
}

@test "the printed filter is a valid jq select() over a list-packages object" {
  run impacted app/run.sh
  filter="$output"
  run jq -c "[.[] | select($filter)] | map(.location)" <<<'[{"location":"lib"},{"location":"app"},{"location":"tool"}]'
  [ "$status" -eq 0 ]
  [ "$output" = '["app","tool"]' ]
}
