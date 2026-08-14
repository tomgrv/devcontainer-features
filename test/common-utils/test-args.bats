#!/usr/bin/env bats

load helpers

setup() {
    setup_common_utils_path
}

teardown() {
    teardown_common_utils_path
}

@test "flag value: injection blocked" {
    marker="$BATS_TEST_TMPDIR/pwned"
    payload="a'; touch '$marker'; echo '"
    eval "$(zz_args "test" caller -t "$payload" <<-EOF
	t value target    target value
EOF
)"
    [ ! -f "$marker" ]
}

@test "positional (-): injection blocked" {
    marker="$BATS_TEST_TMPDIR/pwned"
    payload="a'; touch '$marker'; echo '"
    eval "$(zz_args "test" caller "$payload" <<-EOF
	- target target    target value
EOF
)"
    [ ! -f "$marker" ]
}

@test "& capture: injection blocked" {
    marker="$BATS_TEST_TMPDIR/pwned"
    payload="a'; touch '$marker'; echo '"
    eval "$(zz_args "test" caller "$payload" "second" <<-EOF
	& body body    remaining lines
EOF
)"
    [ ! -f "$marker" ]
}

@test "# capture: injection blocked" {
    marker="$BATS_TEST_TMPDIR/pwned"
    payload="a'; touch '$marker'; echo '"
    eval "$(zz_args "test" caller "$payload" "second word" <<-EOF
	# body body    remaining escaped
EOF
)"
    [ ! -f "$marker" ]
}

@test "+ capture: injection blocked" {
    marker="$BATS_TEST_TMPDIR/pwned"
    payload="a'; touch '$marker'; echo '"
    eval "$(zz_args "test" caller "$payload" "second" <<-EOF
	+ msg message    remaining args
EOF
)"
    [ ! -f "$marker" ]
}

@test "positional (-): normal value parses" {
    target=""
    eval "$(zz_args "test" caller "my-branch" <<-EOF
	- target target    target value
EOF
)"
    [ "$target" = "my-branch" ]
}

@test "+ capture: normal value parses" {
    message=""
    eval "$(zz_args "test" caller "hello" "world" <<-EOF
	+ msg message    remaining args
EOF
)"
    [ "$message" = "hello world" ]
}

@test "positional (-): apostrophe round-trips" {
    target=""
    eval "$(zz_args "test" caller "don't stop" <<-EOF
	- target target    target value
EOF
)"
    [ "$target" = "don't stop" ]
}

@test "flag value: normal value parses" {
    target=""
    eval "$(zz_args "test" caller -t "my-value" <<-EOF
	t value target    target value
EOF
)"
    [ "$target" = "my-value" ]
}

@test "flag (-): set when passed" {
    push=""
    eval "$(zz_args "test" caller -p <<-EOF
	p -      push      push flag
EOF
)"
    [ "$push" = "-p" ]
}

@test "flag (-): left untouched when absent" {
    push="untouched"
    eval "$(zz_args "test" caller <<-EOF
	p -      push      push flag
EOF
)"
    [ "$push" = "untouched" ]
}

@test "combined spec: push" {
    push=""
    dryrun=""
    target=""
    source=""
    eval "$(zz_args "test" caller -p -n mybranch upstream <<-EOF
	p -      push      push flag
	n -      dryrun    dry-run flag
	- target target    target value
	- source source    source value
EOF
)"
    [ "$push" = "-p" ]
}

@test "combined spec: dryrun" {
    push=""
    dryrun=""
    target=""
    source=""
    eval "$(zz_args "test" caller -p -n mybranch upstream <<-EOF
	p -      push      push flag
	n -      dryrun    dry-run flag
	- target target    target value
	- source source    source value
EOF
)"
    [ "$dryrun" = "-n" ]
}

@test "combined spec: target" {
    push=""
    dryrun=""
    target=""
    source=""
    eval "$(zz_args "test" caller -p -n mybranch upstream <<-EOF
	p -      push      push flag
	n -      dryrun    dry-run flag
	- target target    target value
	- source source    source value
EOF
)"
    [ "$target" = "mybranch" ]
}

@test "combined spec: source" {
    push=""
    dryrun=""
    target=""
    source=""
    eval "$(zz_args "test" caller -p -n mybranch upstream <<-EOF
	p -      push      push flag
	n -      dryrun    dry-run flag
	- target target    target value
	- source source    source value
EOF
)"
    [ "$source" = "upstream" ]
}

@test "combined spec: target still parses alone" {
    target=""
    source="untouched"
    eval "$(zz_args "test" caller mybranch <<-EOF
	- target target    target value
	- source source    source value
EOF
)"
    [ "$target" = "mybranch" ]
}

@test "combined spec: omitted trailing positional untouched" {
    target=""
    source="untouched"
    eval "$(zz_args "test" caller mybranch <<-EOF
	- target target    target value
	- source source    source value
EOF
)"
    [ "$source" = "untouched" ]
}

@test "& capture: normal values join with literal backslash-n" {
    body=""
    eval "$(zz_args "test" caller "one" "two words" <<-EOF
	& body body    remaining lines
EOF
)"
    [ "$body" = 'one\ntwo words' ]
}

@test "# capture: normal values escape internal spaces" {
    body=""
    eval "$(zz_args "test" caller "hello world" "foo" <<-EOF
	# body body    remaining escaped
EOF
)"
    [ "$body" = 'hello\ world foo' ]
}

@test "-h: caller eval exits 1" {
    run_h() {
        eval "$(zz_args "My Title" caller -h <<-EOF
	- target target    target value
EOF
)"
    }
    run run_h
    [ "$status" -eq 1 ]
}

@test "-h: usage banner printed" {
    run_h() {
        eval "$(zz_args "My Title" caller -h <<-EOF
	- target target    target value
EOF
)"
    }
    run run_h
    [[ "$output" == *"Usage:"* ]]
}

# Regression guard: zz_args builds a "varnames" table by concatenating
# literal \n/\t into a plain string (not real control characters), then
# reads it back to bind "-"/"+"/"&"/"#" positional args. That readback used
# to mix `echo -e` (one call site) with plain `echo` (four call sites) —
# the plain ones only split correctly on shells whose `echo` builtin
# auto-expands backslash escapes (true for dash's XSI echo, false for
# bash's builtin and other POSIX-strict shells), so cmd/target silently
# came out empty on those shells regardless of what was actually passed.
# The test runner's /bin/sh is dash on CI, which would never trip this, so
# force the parse through bash explicitly.
@test "positional (-) binds under bash's non-XSI echo (regression)" {
    run bash -c '
        eval "$(bash "'"$REPO_ROOT"'/src/common-utils/_zz_args.sh" "test" caller "add" "gateway" <<-EOF
	- cmd cmd       command
	+ target target target value
EOF
)"
        echo "cmd=[$cmd] target=[$target]"
    '
    [ "$output" = "cmd=[add] target=[gateway]" ]
}

@test "+ capture binds under bash's non-XSI echo (regression)" {
    run bash -c '
        eval "$(bash "'"$REPO_ROOT"'/src/common-utils/_zz_args.sh" "test" caller "hello" "world" <<-EOF
	+ msg message    remaining args
EOF
)"
        echo "message=[$message]"
    '
    [ "$output" = "message=[hello world]" ]
}
