#!/usr/bin/env bats
# Covers the stub-deploy loop's qualifier-collapse dest logic in
# _configure-feature.sh (_<qualifier>.<yyy.ext> -> <yyy.ext>), now that it's
# the only merge mechanism (the old dedicated package/composer merge pass
# was removed in favor of routing those fragments through stubs/ too).

load helpers

setup() {
    setup_common_utils_path
    work="$BATS_TEST_TMPDIR"
    source_dir="$work/feature"
    target_dir="$work/target"
    mkdir -p "$source_dir/stubs" "$target_dir"
}

teardown() {
    teardown_common_utils_path
}

@test "single qualifier-prefixed fragment seeds a missing destination" {
    cat >"$source_dir/stubs/_update.package.json" <<'EOF'
{"scripts": {"update": "npm-check-updates -i -u"}}
EOF

    (cd "$target_dir" && configure-feature -s "$source_dir" myfeature)

    [ -f "$target_dir/package.json" ]
    [ "$(jq -c '.scripts.update' "$target_dir/package.json")" = '"npm-check-updates -i -u"' ]
}

@test "multiple same-target fragments accumulate via merge-json" {
    cat >"$source_dir/stubs/_commitlint.package.json" <<'EOF'
{"devDependencies": {"@commitlint/cli": "*"}}
EOF
    cat >"$source_dir/stubs/_prettier.package.json" <<'EOF'
{"devDependencies": {"prettier": "*"}}
EOF

    (cd "$target_dir" && configure-feature -s "$source_dir" myfeature)

    [ -f "$target_dir/package.json" ]
    [ "$(jq -c '.devDependencies | keys' "$target_dir/package.json")" = '["@commitlint/cli","prettier"]' ]
}

@test "existing destination content is preserved and merged, not clobbered" {
    cat >"$target_dir/package.json" <<'EOF'
{"name": "consumer-app", "scripts": {"build": "tsc"}}
EOF
    cat >"$source_dir/stubs/_scripts.package.json" <<'EOF'
{"scripts": {"lint": "eslint ."}}
EOF

    (cd "$target_dir" && configure-feature -s "$source_dir" myfeature)

    [ "$(jq -r '.name' "$target_dir/package.json")" = "consumer-app" ]
    [ "$(jq -r '.scripts.build' "$target_dir/package.json")" = "tsc" ]
    [ "$(jq -r '.scripts.lint' "$target_dir/package.json")" = "eslint ." ]
}

@test "nested target path resolves under its own folder" {
    mkdir -p "$source_dir/stubs/.vscode"
    cat >"$source_dir/stubs/.vscode/_helper.tasks.json" <<'EOF'
{"version": "2.0.0", "tasks": []}
EOF

    (cd "$target_dir" && configure-feature -s "$source_dir" myfeature)

    [ -f "$target_dir/.vscode/tasks.json" ]
    [ "$(jq -r '.version' "$target_dir/.vscode/tasks.json")" = "2.0.0" ]
}

@test "plain stub file (no qualifier prefix) deploys verbatim, unaffected by collapse" {
    echo "hello" >"$source_dir/stubs/plain.txt"

    (cd "$target_dir" && configure-feature -s "$source_dir" myfeature)

    [ "$(cat "$target_dir/plain.txt")" = "hello" ]
}
