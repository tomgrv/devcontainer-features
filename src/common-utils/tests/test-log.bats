#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
}

teardown() {
    teardown_common_utils_path
}

@test "info level: message text present" {
    run zz_log i "hello world"
    [[ "$output" == *"hello world"* ]]
}

@test "info level: pictogram present" {
    run zz_log i "hello"
    [[ "$output" == *"→"* ]]
}

@test "warning level: pictogram present" {
    run zz_log w "careful"
    [[ "$output" == *"!"* ]]
}

@test "error level: pictogram present" {
    run zz_log e "bad"
    [[ "$output" == *"✕"* ]]
}

@test "success level: pictogram present" {
    run zz_log s "done"
    [[ "$output" == *"✔"* ]]
}

@test "dash level: indented, no pictogram" {
    run zz_log - "plain"
    [[ "$output" == "  plain"* ]]
}

@test "unknown level: level text used as pictogram" {
    run zz_log custom "text"
    [[ "$output" == "custom text"* ]]
}

@test "multiple words are joined back with spaces" {
    run zz_log i "one" "two" "three"
    [[ "$output" == *"one two three"* ]]
}

@test "writes to stderr, not stdout" {
    out="$(zz_log i "to stderr" 2>/dev/null)"
    [ -z "$out" ]
}

@test "reaches stderr when read from there" {
    err="$(zz_log i "to stderr" 2>&1 >/dev/null)"
    [[ "$err" == *"to stderr"* ]]
}

# Regression guard: color codes must be real ESC bytes. zz_log builds its
# output via a generated `printf '%b' "..."` call so \033 color escapes
# expand regardless of the shell's echo builtin (dash's is XSI/auto-
# expanding, bash's and other POSIX-strict shells' are not) — see the
# printf '%b' fix in _zz_log.sh and _zz_args.sh.
@test "color escapes are real ESC bytes, not literal backslash text" {
    run zz_log i "hello"
    [[ "$output" == *$'\x1b['* ]]
}

@test "no literal backslash-033 leaks into the output" {
    run zz_log i "hello"
    [[ "$output" != *'\033'* ]]
}

@test "message ends with a reset escape sequence" {
    run zz_log i "hello"
    [[ "$output" == *$'\x1b[0m'* ]]
}

@test "{COLOR text} markup is consumed, not printed literally" {
    run zz_log i "click {U here} now"
    [[ "$output" != *"{U"* ]]
    [[ "$output" == *"here"* ]]
    [[ "$output" == *"now"* ]]
}

# Same escape-expansion guard, forced through bash's non-XSI echo builtin
# instead of relying on the test runner's /bin/sh (dash on CI, which would
# mask the bug this regression is meant to catch).
@test "escape expansion holds under bash's non-XSI echo (regression)" {
    run bash "$REPO_ROOT/src/common-utils/bins/_zz_log.sh" i "hello"
    [[ "$output" == *$'\x1b['* ]]
    [[ "$output" != *'\033'* ]]
}
