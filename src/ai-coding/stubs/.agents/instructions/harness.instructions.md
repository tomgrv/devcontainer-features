---
applyTo: '**'
description: 'Long-running agent harness: durable state files, fixed startup loop, evidence-gated completion.'
---

<!-- @format -->

## Harness Rules

Applies when `claude-progress.md` or `feature_list.json` exists at the repo root. Otherwise the `harness` skill sets them up on request.

- The repo is the system of record. Persist state in files, not chat.
- Start every session: `pwd` → read `claude-progress.md` → read `feature_list.json` → `git log --oneline -5` → `./init.sh` → baseline check. Broken baseline: fix it first.
- One feature at a time. Stay inside its scope.
- `passing` only after the feature's `verification` ran and evidence is recorded. Never weaken tests, rewrite the list, or loosen verification to finish.
- Before stopping: update `claude-progress.md` and `feature_list.json`, then commit in a restartable state.
- Full procedure and templates: the `harness` skill.
