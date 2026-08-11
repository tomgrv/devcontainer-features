#!/bin/sh
set -e

. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat >"$work/schema.json" <<'EOF'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "additionalProperties": true
}
EOF

cat >"$work/file.json" <<'EOF'
{"b": 2, "a": 1}
EOF

normalize-json -w -t 2 -s "$work/schema.json" "$work/file.json" >/dev/null 2>&1

assert_eq "normalized file keeps the same data (keys sorted)" \
    '{"a":1,"b":2}' \
    "$(jq -Sc '.' "$work/file.json")"

assert_eq "normalized file is indented with requested tab size" \
    '{
  "a": 1,' \
    "$(head -n 2 "$work/file.json")"

report
