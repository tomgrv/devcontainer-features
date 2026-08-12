#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
    work="$BATS_TEST_TMPDIR"

    cat >"$work/schema.json" <<'EOF'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": { "type": "string" }
    }
}
EOF

    cat >"$work/valid.json" <<'EOF'
{"name": "ok"}
EOF

    cat >"$work/invalid.json" <<'EOF'
{"other": 1}
EOF
}

teardown() {
    teardown_common_utils_path
}

@test "json matching schema passes" {
    status=0
    validate-json -s "$work/schema.json" "$work/valid.json" >/dev/null 2>&1 || status=$?
    [ "$status" -eq 0 ]
}

@test "json missing required property fails" {
    status=0
    validate-json -s "$work/schema.json" "$work/invalid.json" >/dev/null 2>&1 || status=$?
    [ "$status" -eq 1 ]
}
