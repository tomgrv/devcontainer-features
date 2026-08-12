#!/bin/sh
set -e

. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# --- source order is preserved: arrays keep first-seen order, not sorted ---
cat > "$work/target.json" << 'EOF'
{"a": 1, "b": [1, 2, 3], "c": {"x": 1}}
EOF
cat > "$work/source.json" << 'EOF'
{"b": [3, 4, 5], "d": 9, "c": {"y": 2}}
EOF

merge-json "$work/target.json" "$work/source.json" > /dev/null 2>&1

assert_eq "array merge keeps first-seen order (no sort)" \
    "[1,2,3,4,5]" \
    "$(jq -c '.b' "$work/target.json")"

assert_eq "object keys keep target order then new source keys" \
    '["a","b","c","d"]' \
    "$(jq -c 'keys_unsorted' "$work/target.json")"

assert_eq "nested objects are merged" \
    '{"x":1,"y":2}' \
    "$(jq -c '.c' "$work/target.json")"

# --- array merge dedupes ---
cat > "$work/target2.json" << 'EOF'
{"tags": ["a", "b"]}
EOF
cat > "$work/source2.json" << 'EOF'
{"tags": ["b", "c"]}
EOF

merge-json "$work/target2.json" "$work/source2.json" > /dev/null 2>&1

assert_eq "array merge dedupes repeated values" \
    '["a","b","c"]' \
    "$(jq -c '.tags' "$work/target2.json")"

# --- array merge dedupes when elements are themselves arrays (jq's ---
# --- `index` treats an array needle as a subsequence pattern, not an ---
# --- element to match, so a naive index-based dedupe silently fails) ---
cat > "$work/target3.json" << 'EOF'
{"pairs": [[1, 2], [3, 4]]}
EOF
cat > "$work/source3.json" << 'EOF'
{"pairs": [[1, 2], [5, 6]]}
EOF

merge-json "$work/target3.json" "$work/source3.json" > /dev/null 2>&1

assert_eq "array merge dedupes repeated array elements" \
    '[[1,2],[3,4],[5,6]]' \
    "$(jq -c '.pairs' "$work/target3.json")"

# --- error cases ---
status=0
merge-json "$work/missing.json" "$work/source.json" > /dev/null 2>&1 || status=$?
assert_status "missing target file fails" 1 "$status"

echo "not json" > "$work/invalid.json"
status=0
merge-json "$work/invalid.json" "$work/source.json" > /dev/null 2>&1 || status=$?
assert_status "invalid target JSON fails" 1 "$status"

report
