#!/bin/sh

# Stop hook: blocks the stop once when there is uncommitted work but
# .agents/progress.md was not touched, so a session cannot end without a
# handoff. Opt-in (needs .agents/progress.md); never loops (honours
# stop_hook_active from the hook payload).

grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .agents/progress.md ] || exit 0

[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0
[ -n "$(git status --porcelain -- .agents/progress.md 2>/dev/null)" ] && exit 0

echo "Harness: uncommitted work but .agents/progress.md was not updated. Record the verified state, evidence and next step, update .agents/features.json, then commit." >&2
exit 2
