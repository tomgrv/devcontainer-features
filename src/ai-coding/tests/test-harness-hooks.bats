#!/usr/bin/env bats
# Covers stubs/.claude/hooks/harness-startup.sh and harness-stop.sh: both are
# opt-in (silent without .agents/progress.md / .agents/features.json), the startup
# hook prints the next unfinished feature, the stop hook blocks once on
# uncommitted work without a progress update and never loops.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    git init -q
    git config user.email t@t && git config user.name t
    mkdir -p .claude/hooks .agents
    cp "$FEATURE_DIR"/stubs/.claude/hooks/harness-*.sh .claude/hooks/
    echo x >seed && git add seed && git commit -qm seed
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "startup: silent when the repo has not opted in" {
    run sh .claude/hooks/harness-startup.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "startup: prints the next unfinished feature by priority" {
    echo '# log' >.agents/progress.md
    echo '{"features":[{"id":"b","priority":2,"status":"not_started","title":"B"},{"id":"a","priority":1,"status":"in_progress","title":"A"},{"id":"c","priority":0,"status":"passing","title":"C"},{"id":"d","priority":0,"status":"blocked","title":"D"}]}' >.agents/features.json
    run sh .claude/hooks/harness-startup.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"a [in_progress] A"* ]]
}

@test "startup: lists the repo rule files that exist" {
    echo '# log' >.agents/progress.md
    echo rules >CLAUDE.md
    run sh .claude/hooks/harness-startup.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Repo rules"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "stop: allows when not opted in" {
    echo dirty >>seed
    run sh -c "echo '{}' | sh .claude/hooks/harness-stop.sh"
    [ "$status" -eq 0 ]
}

@test "stop: blocks dirty tree with an untouched progress log" {
    echo '# log' >.agents/progress.md && git add . && git commit -qm log
    echo dirty >>seed
    run sh -c "echo '{}' | sh .claude/hooks/harness-stop.sh"
    [ "$status" -eq 2 ]
}

@test "stop: allows once the progress log changed" {
    echo '# log' >.agents/progress.md && git add . && git commit -qm log
    echo dirty >>seed
    echo update >>.agents/progress.md
    run sh -c "echo '{}' | sh .claude/hooks/harness-stop.sh"
    [ "$status" -eq 0 ]
}

@test "stop: never loops when stop_hook_active is true" {
    echo '# log' >.agents/progress.md && git add . && git commit -qm log
    echo dirty >>seed
    run sh -c "echo '{\"stop_hook_active\": true}' | sh .claude/hooks/harness-stop.sh"
    [ "$status" -eq 0 ]
}

@test "startup: runs the baseline command and reports PASS/FAIL" {
    echo '{"baseline":"true","features":[]}' >.agents/features.json
    run sh .claude/hooks/harness-startup.sh
    [[ "$output" == *"Baseline verification: true"* ]]
    [[ "$output" == *"PASS"* ]]
    echo '{"baseline":"echo boom; false","features":[]}' >.agents/features.json
    run sh .claude/hooks/harness-startup.sh
    [[ "$output" == *"FAIL (exit 1)"* ]]
    [[ "$output" == *"boom"* ]]
}
