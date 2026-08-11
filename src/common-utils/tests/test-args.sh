#!/bin/sh
set -e

. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Marker file a successful shell-injection would create; must never appear.
marker="$work/pwned"
payload="a'; touch '$marker'; echo '"

injected() {
    [ -f "$marker" ] && echo 1 || echo 0
}

# --- flag value capture ('x' with value) ------------------------------------
rm -f "$marker"
eval "$(zz_args "test" caller -t "$payload" <<-EOF
	t value target    target value
EOF
)"
assert_eq "flag value: injection blocked" 0 "$(injected)"

# --- positional '-' capture -------------------------------------------------
rm -f "$marker"
eval "$(zz_args "test" caller "$payload" <<-EOF
	- target target    target value
EOF
)"
assert_eq "positional (-): injection blocked" 0 "$(injected)"

# --- '&' remaining-lines capture --------------------------------------------
rm -f "$marker"
eval "$(zz_args "test" caller "$payload" "second" <<-EOF
	& body body    remaining lines
EOF
)"
assert_eq "& capture: injection blocked" 0 "$(injected)"

# --- '#' remaining-escaped-space capture ------------------------------------
rm -f "$marker"
eval "$(zz_args "test" caller "$payload" "second word" <<-EOF
	# body body    remaining escaped
EOF
)"
assert_eq "# capture: injection blocked" 0 "$(injected)"

# --- '+' remaining-args capture ---------------------------------------------
rm -f "$marker"
eval "$(zz_args "test" caller "$payload" "second" <<-EOF
	+ msg message    remaining args
EOF
)"
assert_eq "+ capture: injection blocked" 0 "$(injected)"

# --- normal values still parse correctly across the fixed modes ------------
rm -f "$marker"
target=""
eval "$(zz_args "test" caller "my-branch" <<-EOF
	- target target    target value
EOF
)"
assert_eq "positional (-): normal value parses" "my-branch" "$target"

rm -f "$marker"
message=""
eval "$(zz_args "test" caller "hello" "world" <<-EOF
	+ msg message    remaining args
EOF
)"
assert_eq "+ capture: normal value parses" "hello world" "$message"

report
