#!/bin/sh
set -e

# Check PHP tests are placed by part (core / modules / packages) so that
# `php-changed` can run only the suites a change can impact:
#   - core tests (tests/) never import Modules\* or package classes
#   - module tests never import another module
#   - tests live in <part>/tests/{Unit,Feature,Browser,Fixtures,Datasets}
#   - test files are named *Test.php
#   - every part with tests has a phpunit.xml suite pointing at its tests dir

cd "$(git rev-parse --show-toplevel)" >/dev/null

errors=0
fail() {
    echo "$1: $2"
    errors=$((errors + 1))
}

parts=$(jq -r '.extra["merge-plugin"].include[]? // empty' composer.json 2>/dev/null |
    sed 's|/composer\.json$||' | while read -r glob; do
    for dir in $glob; do [ -f "$dir/composer.json" ] && echo "$dir"; done
done | sort -u)

# Core: no module/package imports
for f in $(grep -rlE '^use (Modules|Perspikapps|Packages)\\' tests --include='*.php' 2>/dev/null | grep -v '^tests/Failing/' || true); do
    fail "$f" "core test imports a module/package class; move it into that part's tests/"
done

for dir in $parts; do
    [ -n "$(find "$dir/tests" -name "*.php" 2>/dev/null | head -n 1)" ] || continue

    # Modules never depend on other modules
    case $dir in
    modules/*)
        self=$(basename "$dir")
        for f in $(grep -rlE '^use Modules\\' "$dir/tests" --include='*.php' 2>/dev/null || true); do
            if grep -E '^use Modules\\' "$f" | grep -qvE "^use Modules\\\\$self\\\\"; then
                fail "$f" "module test imports another module"
            fi
        done
        ;;
    esac

    # Placement and naming
    for f in $(find "$dir/tests" -name '*.php' -not -path '*/Fixtures/*' -not -path '*/Datasets/*' -not -name 'Pest.php' -not -name 'TestCase.php'); do
        case ${f#"$dir"/tests/} in
        Unit/* | Feature/* | Browser/*) ;;
        *) fail "$f" "test outside tests/{Unit,Feature,Browser}" ;;
        esac
        case $f in
        *Test.php) ;;
        *) grep -qE '^\s*(it|test)\(|extends TestCase' "$f" && fail "$f" "test file not named *Test.php (never discovered)" ;;
        esac
    done

    # Suite registered
    grep -qs "$dir/tests" phpunit.xml phpunit.xml.dist || fail "$dir" "no phpunit.xml testsuite for $dir/tests"
done

if [ "$errors" -gt 0 ]; then
    zz_log e "$errors test layout violation(s)" 2>/dev/null || echo "$errors test layout violation(s)" >&2
    exit 1
fi
