#!/usr/bin/env bats
# @format

# Guards against the two classes of workflow version drift found in
# tomgrv/actions#... / devcontainer-features#180 / scripts#36:
# a `tomgrv/actions/*` reference pinned to a specific release instead of
# the moving major tag, and `actions/checkout` used at more than one
# version across the repo's own workflows.

setup() {
  WORKFLOWS_DIR="${BATS_TEST_DIRNAME}/../../.github/workflows"
}

@test "tomgrv/actions references use a moving major tag, not a specific release or branch" {
  run grep -rhoE 'tomgrv/actions/[A-Za-z0-9_-]+@[A-Za-z0-9._-]+' "$WORKFLOWS_DIR"
  [ "$status" -eq 0 ]

  offenders=$(echo "$output" | grep -vE '@v[0-9]+$' || true)

  if [ -n "$offenders" ]; then
    echo "Found tomgrv/actions references not pinned to a moving major tag (@vN):"
    echo "$offenders"
    return 1
  fi
}

@test "actions/checkout is pinned to a single version across all workflows" {
  run grep -rhoE 'actions/checkout@v[0-9]+' "$WORKFLOWS_DIR"
  [ "$status" -eq 0 ]

  versions=$(echo "$output" | sort -u)
  count=$(echo "$versions" | wc -l)

  if [ "$count" -ne 1 ]; then
    echo "Expected a single actions/checkout version, found:"
    echo "$versions"
    return 1
  fi
}
