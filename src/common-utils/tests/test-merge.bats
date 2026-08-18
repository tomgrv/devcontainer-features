#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
    work="$BATS_TEST_TMPDIR"
}

teardown() {
    teardown_common_utils_path
}

@test "array merge keeps first-seen order (no sort)" {
    cat >"$work/target.json" <<'EOF'
{"a": 1, "b": [1, 2, 3], "c": {"x": 1}}
EOF
    cat >"$work/source.json" <<'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF
    merge-json "$work/target.json" "$work/source.json" >/dev/null 2>&1

    [ "$(jq -c '.b' "$work/target.json")" = "[1,2,3,4,5]" ]
}

@test "object keys keep target order then new source keys" {
    cat >"$work/target.json" <<'EOF'
{"a": 1, "b": [1, 2, 3], "c": {"x": 1}}
EOF
    cat >"$work/source.json" <<'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF
    merge-json "$work/target.json" "$work/source.json" >/dev/null 2>&1

    [ "$(jq -c 'keys_unsorted' "$work/target.json")" = '["a","b","c","d"]' ]
}

@test "nested objects are merged" {
    cat >"$work/target.json" <<'EOF'
{"a": 1, "b": [1, 2, 3], "c": {"x": 1}}
EOF
    cat >"$work/source.json" <<'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF
    merge-json "$work/target.json" "$work/source.json" >/dev/null 2>&1

    [ "$(jq -c '.c' "$work/target.json")" = '{"x":1,"y":2}' ]
}

@test "array merge dedupes repeated values" {
    cat >"$work/target2.json" <<'EOF'
{"tags": ["a", "b"]}
EOF
    cat >"$work/source2.json" <<'EOF'
{"tags": ["b", "c"]}
EOF
    merge-json "$work/target2.json" "$work/source2.json" >/dev/null 2>&1

    [ "$(jq -c '.tags' "$work/target2.json")" = '["a","b","c"]' ]
}

@test "array merge dedupes repeated array elements" {
    # jq's `index` treats an array needle as a subsequence pattern, not an
    # element to match, so a naive index-based dedupe silently fails here.
    cat >"$work/target3.json" <<'EOF'
{"pairs": [[1, 2], [3, 4]]}
EOF
    cat >"$work/source3.json" <<'EOF'
{"pairs": [[1, 2], [5, 6]]}
EOF
    merge-json "$work/target3.json" "$work/source3.json" >/dev/null 2>&1

    [ "$(jq -c '.pairs' "$work/target3.json")" = '[[1,2],[3,4],[5,6]]' ]
}

@test "missing target file fails" {
    cat >"$work/source.json" <<'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF
    status=0
    merge-json "$work/missing.json" "$work/source.json" >/dev/null 2>&1 || status=$?
    [ "$status" -eq 1 ]
}

@test "invalid target JSON fails" {
    cat >"$work/source.json" <<'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF
    echo "not json" >"$work/invalid.json"
    status=0
    merge-json "$work/invalid.json" "$work/source.json" >/dev/null 2>&1 || status=$?
    [ "$status" -eq 1 ]
}
