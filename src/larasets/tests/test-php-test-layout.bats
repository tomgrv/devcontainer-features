#!/usr/bin/env bats
# Covers bin/php-test-layout.sh: tests are placed by part (core / modules /
# packages) so php-list-changed can run only the impacted suites.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init -q
    cat >composer.json <<'JSON'
{"extra":{"merge-plugin":{"include":["modules/*/composer.json","packages/*/*/composer.json"]}}}
JSON
    mkdir -p tests/Unit modules/Blog/tests/Feature modules/Shop/tests/Feature packages/acme/lib/tests/Unit
    for d in modules/Blog modules/Shop packages/acme/lib; do echo '{}' >"$d/composer.json"; done
    echo "<?php // core" >tests/Unit/CoreTest.php
    echo "<?php // blog" >modules/Blog/tests/Feature/BlogTest.php
    echo "<?php // shop" >modules/Shop/tests/Feature/ShopTest.php
    echo "<?php // lib" >packages/acme/lib/tests/Unit/LibTest.php
    cat >phpunit.xml <<'XML'
<phpunit><testsuites>
<testsuite name="Unit"><directory>tests/Unit</directory></testsuite>
<testsuite name="Blog"><directory>modules/Blog/tests</directory></testsuite>
<testsuite name="Shop"><directory>modules/Shop/tests</directory></testsuite>
<testsuite name="lib"><directory>packages/acme/lib/tests</directory></testsuite>
</testsuites></phpunit>
XML
    STUB_BIN="$TEST_DIR/stub-bin"
    mkdir -p "$STUB_BIN"
    printf '#!/bin/sh\nexit 0\n' >"$STUB_BIN/zz_log"
    chmod +x "$STUB_BIN/zz_log"
    export PATH="$STUB_BIN:$PATH"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

layout() { sh "$FEATURE_DIR/bin/php-test-layout.sh"; }

@test "clean layout passes" {
    run layout
    [ "$status" -eq 0 ]
}

@test "core test importing a module class is flagged" {
    printf '<?php\nuse Modules\\Blog\\Models\\Post;\n' >tests/Unit/CoreTest.php
    run layout
    [ "$status" -eq 1 ]
    [[ "$output" == *"tests/Unit/CoreTest.php: core test imports a module/package class"* ]]
}

@test "module test importing another module is flagged" {
    printf '<?php\nuse Modules\\Shop\\Models\\Item;\n' >modules/Blog/tests/Feature/BlogTest.php
    run layout
    [ "$status" -eq 1 ]
    [[ "$output" == *"module test imports another module"* ]]
}

@test "module test importing its own module is allowed" {
    printf '<?php\nuse Modules\\Blog\\Models\\Post;\n' >modules/Blog/tests/Feature/BlogTest.php
    run layout
    [ "$status" -eq 0 ]
}

@test "test outside Unit/Feature is flagged" {
    echo "<?php // stray" >modules/Blog/tests/StrayTest.php
    run layout
    [ "$status" -eq 1 ]
    [[ "$output" == *"modules/Blog/tests/StrayTest.php: test outside"* ]]
}

@test "test file not named *Test.php is flagged" {
    printf '<?php\nit("works", fn () => true);\n' >modules/Blog/tests/Feature/Navigation.php
    run layout
    [ "$status" -eq 1 ]
    [[ "$output" == *"Navigation.php: test file not named *Test.php"* ]]
}

@test "part without a phpunit.xml suite is flagged" {
    sed -i '/modules\/Shop\/tests/d' phpunit.xml
    run layout
    [ "$status" -eq 1 ]
    [[ "$output" == *"modules/Shop: no phpunit.xml testsuite"* ]]
}

@test "part with an empty tests directory is ignored" {
    mkdir -p modules/Empty/tests/Unit
    echo '{}' >modules/Empty/composer.json
    touch modules/Empty/tests/Unit/.gitkeep
    run layout
    [ "$status" -eq 0 ]
}
