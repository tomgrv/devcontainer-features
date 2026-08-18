#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
}

teardown() {
    teardown_common_utils_path
}

@test "forced source/target: results printed on stdout" {
    run zz_context -s /tmp -t /tmp/zz-context-test-target
    [[ "$output" == *"source=/tmp"* ]]
    [[ "$output" == *"feature=tmp"* ]]
    [[ "$output" == *"target=/tmp/zz-context-test-target"* ]]
}

@test "forced source/target: target directory created" {
    target="$BATS_TEST_TMPDIR/zz-context-created"
    run zz_context -s /tmp -t "$target"
    [ -d "$target" ]
}

@test "forced source/target: feature name strips trailing _number suffix" {
    src="$BATS_TEST_TMPDIR/myfeature_1"
    mkdir -p "$src"
    run zz_context -s "$src" -t "$BATS_TEST_TMPDIR/out"
    [[ "$output" == *"feature=myfeature"* ]]
}

@test "success summary: routed through zz_log, not raw echo" {
    run zz_context -s /tmp -t /tmp/zz-context-test-target
    [[ "$output" == *"Selected context for"* ]]
}

@test "success summary: pictogram from zz_log success level present" {
    run zz_context -s /tmp -t /tmp/zz-context-test-target
    [[ "$output" == *"✔"* ]]
}

@test "success summary: color escapes are real ESC bytes, not literal backslash text" {
    run zz_context -s /tmp -t /tmp/zz-context-test-target
    [[ "$output" == *$'\x1b['* ]]
    [[ "$output" != *'\033'* ]]
}

@test "success summary: {COLOR text} markup consumed, not printed literally" {
    run zz_context -s /tmp -t /tmp/zz-context-test-target
    [[ "$output" != *"{Purple"* ]]
    [[ "$output" != *"{U"* ]]
}

@test "success summary: written to stderr" {
    out="$(zz_context -s /tmp -t /tmp/zz-context-test-target 2>/dev/null)"
    [[ "$out" != *"Selected context for"* ]]
}

@test "success summary: reaches stderr when read from there" {
    err="$(zz_context -s /tmp -t /tmp/zz-context-test-target 2>&1 >/dev/null)"
    [[ "$err" == *"Selected context for"* ]]
}

@test "results (source/feature/target): written to stdout, not stderr" {
    out="$(zz_context -s /tmp -t /tmp/zz-context-test-target 2>/dev/null)"
    [[ "$out" == *"source=/tmp"* ]]
}

