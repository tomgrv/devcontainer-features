#!/usr/bin/env bats
# @format

# Guards the GitLab CI fragments (stubs/**/_<name>...gitlab-ci.yml), the
# counterparts of the GitHub workflows: each must deploy to the dotted
# `.gitlab-ci.yml`, merge with the others without clashing jobs, extend
# templates that exist, and call tomgrv/actions only through `zz-use -x`.

setup() {
  ROOT="${BATS_TEST_DIRNAME}/.."
  FRAGMENTS=$(ls "$ROOT"/src/*/stubs/_*gitlab-ci.yml "$ROOT"/stubs/_*gitlab-ci.yml)
}

# feature-configure's stub naming: `..` collapses to `.`, then a `_` qualifier
# is stripped up to the first `.`.
deployed_name() {
  base=$(basename "$1" | sed 's/\.\./\./g')
  base=${base#_}
  echo "${base#*.}"
}

@test "every fragment deploys to the dotted .gitlab-ci.yml" {
  for f in $FRAGMENTS; do
    [ "$(deployed_name "$f")" = ".gitlab-ci.yml" ] || {
      echo "$f deploys as $(deployed_name "$f")"
      return 1
    }
  done
}

@test "every GitHub workflow stub has a GitLab fragment of the same name" {
  for w in "$ROOT"/src/*/stubs/.github/workflows/*.y*ml "$ROOT"/stubs/.github/workflows/*.y*ml; do
    name=$(basename "$w")
    name=${name%.*}
    ls "$(dirname "$w")"/../../_"$name"...gitlab-ci.yml >/dev/null 2>&1 || {
      echo "no GitLab fragment for $w"
      return 1
    }
  done
}

# Top-level keys sit at column 0 in the fragments (no flow-style mappings).
top_keys() {
  grep -hoE '^[^ #-][^:]*' "$@"
}

@test "fragments are valid YAML" {
  python3 -c 'import yaml' 2>/dev/null || skip "PyYAML is not installed"
  # `!reference` is a GitLab tag PyYAML does not know: ignore it.
  load='import sys, yaml; yaml.SafeLoader.add_multi_constructor("!", lambda l, s, n: None); [yaml.load(open(f), Loader=yaml.SafeLoader) for f in sys.argv[1:]]'
  python3 -c "$load" $FRAGMENTS
}

@test "no job is defined in two fragments" {
  dups=$(top_keys $FRAGMENTS | sort | uniq -d)
  [ -z "$dups" ] || {
    echo "defined in several fragments: $dups"
    return 1
  }
}

@test "every extends targets a template defined in a fragment" {
  defined=$(top_keys $FRAGMENTS)
  for t in $(grep -hoE '^  extends: .*' $FRAGMENTS | sed 's/^  extends: //' | sort -u); do
    echo "$defined" | grep -qx -- "$t" || {
      echo "extends $t, defined nowhere"
      return 1
    }
  done
}

@test "tomgrv/actions are called through zz-use -x, without a GitHub-style pin" {
  run grep -rhE 'tomgrv/actions/[A-Za-z0-9_-]+@|uses:' $FRAGMENTS
  [ "$status" -eq 1 ]
}
