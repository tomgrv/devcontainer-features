#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
    work="$BATS_TEST_TMPDIR"

    cat >"$work/schema.json" <<'EOF'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "additionalProperties": true
}
EOF

    cat >"$work/file.json" <<'EOF'
{"b": 2, "a": 1}
EOF

    normalize-json -w -t 2 -s "$work/schema.json" "$work/file.json" >/dev/null 2>&1
}

teardown() {
    teardown_common_utils_path
}

@test "normalized file keeps the same data (keys sorted)" {
    [ "$(jq -Sc '.' "$work/file.json")" = '{"a":1,"b":2}' ]
}

@test "normalized file is indented with requested tab size" {
    expected='{
  "a": 1,'
    [ "$(head -n 2 "$work/file.json")" = "$expected" ]
}
