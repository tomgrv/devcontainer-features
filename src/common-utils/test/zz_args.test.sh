#!/bin/sh
# Regression tests for _zz_args.sh: confirms argument values containing
# shell metacharacters (single quotes in particular) cannot break out of
# the `var='...'` assignments zz_args emits for the caller's `eval`, and
# that normal argument parsing across all capture modes still works.
#
# Usage: sh src/common-utils/test/zz_args.test.sh
# Exits 0 if all cases pass, 1 otherwise.

set -u

script_dir=$(cd "$(dirname "$0")" && pwd)
common_utils_dir=$(cd "$script_dir/.." && pwd)

test_root=$(mktemp -d)
bin_dir="$test_root/bin"
mkdir -p "$bin_dir"
cp "$common_utils_dir/_zz_args.sh" "$bin_dir/zz_args"
cp "$common_utils_dir/_zz_colors.sh" "$bin_dir/zz_colors"
chmod +x "$bin_dir/zz_args" "$bin_dir/zz_colors"

cleanup() {
    rm -rf "$test_root"
}
trap cleanup EXIT

failures=0

# Marker file a successful injection would create; must never appear.
marker="$test_root/pwned"
payload="a'; touch '$marker'; echo '"

assert() {
    description=$1
    condition=$2
    if [ "$condition" = "0" ]; then
        echo "PASS: $description"
    else
        echo "FAIL: $description"
        failures=$((failures + 1))
    fi
}

assert_no_injection() {
    label=$1
    if [ -f "$marker" ]; then
        assert "$label: injection blocked" 1
    else
        assert "$label: injection blocked" 0
    fi
}

# --- positional '-' capture -------------------------------------------------
rm -f "$marker"
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "$payload" <<-EOF
	- target target    target value
EOF
)"
assert_no_injection "positional (-)"

# --- flag value capture -----------------------------------------------------
rm -f "$marker"
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller -t "$payload" <<-EOF
	t value target    target value
EOF
)"
assert_no_injection "flag value"

# --- '&' remaining-lines capture --------------------------------------------
rm -f "$marker"
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "$payload" "second" <<-EOF
	& body body    remaining lines
EOF
)"
assert_no_injection "& capture"

# --- '#' remaining-escaped-space capture ------------------------------------
rm -f "$marker"
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "$payload" "second word" <<-EOF
	# body body    remaining escaped
EOF
)"
assert_no_injection "# capture"

# --- '+' remaining-args capture ---------------------------------------------
rm -f "$marker"
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "$payload" "second" <<-EOF
	+ msg message    remaining args
EOF
)"
assert_no_injection "+ capture"

# --- normal values still parse correctly ------------------------------------
rm -f "$marker"
target=""
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "my-branch" <<-EOF
	- target target    target value
EOF
)"
[ "$target" = "my-branch" ] && assert "positional (-): normal value parses" 0 || assert "positional (-): normal value parses ($target)" 1

rm -f "$marker"
message=""
eval "$(PATH="$bin_dir:$PATH" zz_args "test" caller "hello" "world" <<-EOF
	+ msg message    remaining args
EOF
)"
[ "$message" = "hello world" ] && assert "+ capture: normal value parses" 0 || assert "+ capture: normal value parses ($message)" 1

if [ "$failures" -eq 0 ]; then
    echo "All zz_args tests passed."
    exit 0
else
    echo "$failures zz_args test(s) failed."
    exit 1
fi
