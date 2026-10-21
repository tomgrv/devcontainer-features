# Progress Log

Session log for long-running agent work (harness: `.agents/skills/harness`). Read at session start, update before handoff.

## Current Verified State

- Standard startup: `SessionStart` hook (prints this state, runs `baseline` from `.agents/features.json`; deps come from the devcontainer features)
- Standard verification: the `baseline` command (`bats -r tests src`: repo-wide tests + every workspace); CI = `.github/workflows/test-workspaces.yaml` (`Tests green`)
- Highest-priority actionable feature: `harness-001` (`ci-001` is blocked on repo secrets)
- Current blocker: `KLICKSPLIT_CLIENT_ID` / `KLICKSPLIT_APP_KEY` not set, so `configure-github` cannot make `Tests green` required on `develop`

## Session Log

### Session 001

- Date: 2026-10-21
- Goal: ship the harness to consumers (`ai-coding` stubs) and dogfood it here
- Completed: harness skill/instructions/hooks/evaluator agent; repo rules wired into startup and end-of-session; root state files
- Verification run: `bats src/ai-coding/tests tests` (all pass locally)
- Evidence captured: PR #231 CI green on `e04b0b3`
- Commits: see PR #231
- Known risk or unresolved issue: `Stop` hook blocks once per stop on a dirty tree without a progress update
- Follow-up (same session): generic conventions (minimal changes, Conventional Commits, branch/PR, format, tests) added to `harness.instructions.md`.
- Follow-up: state moved to `.agents/progress.md` + `.agents/features.json`; `init.sh` folded into the `SessionStart` hook (runs `baseline`, no dep install). `baseline` covers all workspaces (`bats -r tests src`). In the offline cloud sandbox 3 `common-utils` install tests fail (the `tomgrv/scripts` archive download fails there: truncated gzip); they pass in CI and in networked devcontainers.
- Next best step: set the Klicksplit secrets (or the branch rule by hand), then loop-engineering skill (`harness-002`)
