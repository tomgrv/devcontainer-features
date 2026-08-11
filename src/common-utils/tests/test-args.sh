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

# --- values containing a legitimate apostrophe still round-trip exactly ----
# (the fix must stop injection without mangling normal quoted text)
rm -f "$marker"
target=""
eval "$(zz_args "test" caller "don't stop" <<-EOF
	- target target    target value
EOF
)"
assert_eq "positional (-): apostrophe round-trips" "don't stop" "$target"

# --- flag with value ('x' datatype) -----------------------------------------
target=""
eval "$(zz_args "test" caller -t "my-value" <<-EOF
	t value target    target value
EOF
)"
assert_eq "flag value: normal value parses" "my-value" "$target"

# --- flag without value ('-' datatype), present and absent ------------------
push=""
eval "$(zz_args "test" caller -p <<-EOF
	p -      push      push flag
EOF
)"
assert_eq "flag (-): set when passed" "-p" "$push"

push="untouched"
eval "$(zz_args "test" caller <<-EOF
	p -      push      push flag
EOF
)"
assert_eq "flag (-): left untouched when absent" "untouched" "$push"

# --- combined spec: value flag + no-value flag + two positionals -----------
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
assert_eq "combined spec: push" "-p" "$push"
assert_eq "combined spec: dryrun" "-n" "$dryrun"
assert_eq "combined spec: target" "mybranch" "$target"
assert_eq "combined spec: source" "upstream" "$source"

# --- missing optional trailing positional leaves it untouched --------------
target=""
source="untouched"
eval "$(zz_args "test" caller mybranch <<-EOF
	- target target    target value
	- source source    source value
EOF
)"
assert_eq "combined spec: target still parses alone" "mybranch" "$target"
assert_eq "combined spec: omitted trailing positional untouched" "untouched" "$source"

# --- '&' capture joins normal multi-word args with a literal \n separator --
body=""
eval "$(zz_args "test" caller "one" "two words" <<-EOF
	& body body    remaining lines
EOF
)"
assert_eq "& capture: normal values join with literal backslash-n" 'one\ntwo words' "$body"

# --- '#' capture joins args with real spaces, escaping internal spaces -----
body=""
eval "$(zz_args "test" caller "hello world" "foo" <<-EOF
	# body body    remaining escaped
EOF
)"
assert_eq "# capture: normal values escape internal spaces" 'hello\ world foo' "$body"

# --- '-h' still prints usage and signals the caller to exit 1 --------------
# Run in a subshell via `if` so `exit 1` (echoed by zz_args for the caller's
# own eval to run) only ends the subshell, and so `set -e` above doesn't
# abort this script on the expected non-zero status.
rm -f "$work/stderr.log"
if (
    eval "$(zz_args "My Title" caller -h <<-EOF
	- target target    target value
EOF
)"
) >/dev/null 2>"$work/stderr.log"; then
    status=0
else
    status=$?
fi
assert_status "-h: caller eval exits 1" 1 "$status"
stderr=$(cat "$work/stderr.log")
case "$stderr" in
*"Usage:"*) assert_eq "-h: usage banner printed" 0 0 ;;
*) assert_eq "-h: usage banner printed (got: $stderr)" 0 1 ;;
esac

report
