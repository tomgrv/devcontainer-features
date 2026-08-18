#!/usr/bin/env bats
# Covers zz_feature.sh's -i (install) mode, and the mode-flag validation
# shared by both modes.

load helpers

setup() {
    setup_common_utils_path
    work="$BATS_TEST_TMPDIR"
    source_dir="$work/feature"
    target_dir="$work/target"
    mkdir -p "$source_dir/stubs" "$source_dir/config" "$source_dir/bin" "$target_dir"
}

teardown() {
    teardown_common_utils_path
}

@test "install mode copies stubs/config/bin into target and makes scripts executable" {
    echo "hello" >"$source_dir/stubs/foo.txt"
    echo '{"a": 1}' >"$source_dir/config/bar.json"
    printf '#!/bin/sh\necho hi\n' >"$source_dir/bin/mycmd.sh"

    zz_feature -i -s "$source_dir" -t "$target_dir"

    [ "$(cat "$target_dir/stubs/foo.txt")" = "hello" ]
    [ -f "$target_dir/config/bar.json" ]
    [ -x "$target_dir/bin/mycmd.sh" ]
}

@test "install mode symlinks bin/ scripts onto a writable PATH directory (formerly install-bin)" {
    printf '#!/bin/sh\necho hi\n' >"$source_dir/bin/mycmd.sh"
    chmod +x "$source_dir/bin/mycmd.sh"
    link_dir="$work/systembin"
    mkdir -p "$link_dir"

    INSTALL_BIN_DIR="$link_dir" zz_feature -i -s "$source_dir" -t "$target_dir"

    [ -L "$link_dir/mycmd" ]
    [ "$(readlink "$link_dir/mycmd")" = "$target_dir/bin/mycmd.sh" ]
    [ "$("$link_dir/mycmd")" = "hi" ]
}

@test "install mode with no bin/ directory installs cleanly without error" {
    rmdir "$source_dir/bin"
    link_dir="$work/systembin"
    mkdir -p "$link_dir"

    run env INSTALL_BIN_DIR="$link_dir" zz_feature -i -s "$source_dir" -t "$target_dir"

    [ "$status" -eq 0 ]
    [ ! -d "$target_dir/bin" ]
}

@test "install mode runs root install-*.sh scripts" {
    cat >"$source_dir/install-marker.sh" <<EOF
#!/bin/sh
echo ran >"$work/marker"
EOF
    chmod +x "$source_dir/install-marker.sh"

    zz_feature -i -s "$source_dir" -t "$target_dir"

    [ "$(cat "$work/marker")" = "ran" ]
}

@test "a stray -i does not leak into args forwarded to install-*.sh scripts" {
    # Regression guard: zz_feature's own \$@ still holds the raw "-i ..."
    # invocation (zz_args/eval doesn't touch it), and it gets forwarded
    # verbatim to every install-*.sh script. Without rebuilding a clean
    # "set --" first, install-*.sh scripts that re-parse "\$@" via zz_context
    # (which has no -i flag) would have their arg parsing silently corrupted.
    cat >"$source_dir/install-record.sh" <<EOF
#!/bin/sh
echo "\$*" >"$work/received-args"
EOF
    chmod +x "$source_dir/install-record.sh"

    zz_feature -i -s "$source_dir" -t "$target_dir"

    received="$(cat "$work/received-args")"
    [ "$received" = "-s $source_dir -t $target_dir" ]
    case "$received" in
    *-i*) fail "received args leaked -i: $received" ;;
    esac
}

@test "passing both -i and -c is an error" {
    run zz_feature -i -c -s "$source_dir" myfeature
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choose one"* ]]
}

@test "passing neither -i nor -c is an error" {
    run zz_feature -s "$source_dir" myfeature
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: zz_feature"* ]]
}
