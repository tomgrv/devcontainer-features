#!/bin/sh
set -e

. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat >"$work/schema.json" <<'EOF'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": { "type": "string" }
    }
}
EOF

cat >"$work/valid.json" <<'EOF'
{"name": "ok"}
EOF

cat >"$work/invalid.json" <<'EOF'
{"other": 1}
EOF

status=0
validate-json -s "$work/schema.json" "$work/valid.json" >/dev/null 2>&1 || status=$?
assert_status "json matching schema passes" 0 "$status"

status=0
validate-json -s "$work/schema.json" "$work/invalid.json" >/dev/null 2>&1 || status=$?
assert_status "json missing required property fails" 1 "$status"

report
