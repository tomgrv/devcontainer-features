#!/usr/bin/env bats
# Covers the stub-deploy loop's qualifier-collapse dest logic in
# zz_feature.sh's -c (configure) mode (_<qualifier>.<yyy.ext> -> <yyy.ext>),
# the only merge mechanism (the old dedicated package/composer merge pass
# was removed in favor of routing those fragments through stubs/ too), and
# the non-JSON accumulation path (line-set reconciliation against a dated
# per-fragment snapshot, since git merge-file can't union two independent
# fragments' additions the way merge-json unions JSON fragments).

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

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

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

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

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

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    [ "$(jq -r '.name' "$target_dir/package.json")" = "consumer-app" ]
    [ "$(jq -r '.scripts.build' "$target_dir/package.json")" = "tsc" ]
    [ "$(jq -r '.scripts.lint' "$target_dir/package.json")" = "eslint ." ]
}

@test "nested target path resolves under its own folder" {
    mkdir -p "$source_dir/stubs/.vscode"
    cat >"$source_dir/stubs/.vscode/_helper.tasks.json" <<'EOF'
{"version": "2.0.0", "tasks": []}
EOF

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    [ -f "$target_dir/.vscode/tasks.json" ]
    [ "$(jq -r '.version' "$target_dir/.vscode/tasks.json")" = "2.0.0" ]
}

@test "plain stub file (no qualifier prefix) deploys verbatim, unaffected by collapse" {
    echo "hello" >"$source_dir/stubs/plain.txt"

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    [ "$(cat "$target_dir/plain.txt")" = "hello" ]
}

@test "non-JSON: two different features' fragments both accumulate into the same dest" {
    other_source="$work/other-feature"
    mkdir -p "$other_source/stubs"

    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n' >"$source_dir/stubs/..gitattributes"
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n.agents export-ignore\n' >"$other_source/stubs/..gitattributes"

    (cd "$target_dir" && zz_feature -c -s "$source_dir" first-feature)
    (cd "$target_dir" && zz_feature -c -s "$other_source" second-feature)

    grep -qxF 'CHANGELOG.md export-ignore' "$target_dir/.gitattributes"
    grep -qxF '.agents export-ignore' "$target_dir/.gitattributes"
}

@test "non-JSON: unchanged fragment is a true no-op on re-deploy, not duplicated" {
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n' >"$source_dir/stubs/..gitattributes"

    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)
    before="$(cat "$target_dir/.gitattributes")"
    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)
    after="$(cat "$target_dir/.gitattributes")"

    [ "$before" = "$after" ]
    [ "$(grep -c 'CHANGELOG.md export-ignore' "$target_dir/.gitattributes")" = 1 ]
}

@test "non-JSON: a fragment's upstream update patches in just its delta" {
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n' >"$source_dir/stubs/..gitattributes"
    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    other_source="$work/other-feature"
    mkdir -p "$other_source/stubs"
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n.agents export-ignore\n' >"$other_source/stubs/..gitattributes"
    (cd "$target_dir" && zz_feature -c -s "$other_source" second-feature)

    # first feature's fragment gains a new line upstream
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n.vscode export-ignore\n' >"$source_dir/stubs/..gitattributes"
    touch "$source_dir/stubs/..gitattributes"
    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    ! grep -q '<<<<<<<' "$target_dir/.gitattributes"
    grep -qxF '.vscode export-ignore' "$target_dir/.gitattributes"
    grep -qxF '.agents export-ignore' "$target_dir/.gitattributes"
}

@test "non-JSON: a line dropped from a fragment's upstream is removed, manual edits survive" {
    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n.devcontainer export-ignore\n' >"$source_dir/stubs/..gitattributes"
    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    printf 'my-custom-file custom-attr\n' >>"$target_dir/.gitattributes"

    printf '* text=auto eol=lf\nCHANGELOG.md export-ignore\n' >"$source_dir/stubs/..gitattributes"
    touch "$source_dir/stubs/..gitattributes"
    (cd "$target_dir" && zz_feature -c -s "$source_dir" myfeature)

    ! grep -qxF '.devcontainer export-ignore' "$target_dir/.gitattributes"
    grep -qxF 'my-custom-file custom-attr' "$target_dir/.gitattributes"
}
