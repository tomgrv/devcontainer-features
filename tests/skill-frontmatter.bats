#!/usr/bin/env bats
# @format

# Guards against SKILL.md files that agents skip for missing frontmatter:
# the `---` block must open the file (not follow `<!-- @format -->`, and not
# be appended at the end by a stub merge) and carry `name` + `description`.

setup() {
  REPO_DIR="${BATS_TEST_DIRNAME}/../.."
}

@test "every SKILL.md opens with frontmatter declaring name and description" {
  offenders=""
  while IFS= read -r f; do
    fm=$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1 {print}' "$f")
    if ! grep -q '^name:' <<<"$fm" || ! grep -q '^description:' <<<"$fm"; then
      offenders+="${f#$REPO_DIR/}"$'\n'
    fi
  done < <(find -L "$REPO_DIR/src" "$REPO_DIR/.agents" "$REPO_DIR/.github" "$REPO_DIR/.claude" \
    -name SKILL.md -not -path '*/node_modules/*' 2>/dev/null)

  if [ -n "$offenders" ]; then
    echo "SKILL.md files without leading name/description frontmatter:"
    echo "$offenders"
    return 1
  fi
}
