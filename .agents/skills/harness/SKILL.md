---
name: harness
description: >
  Set up or run the long-running-agent harness: initialize the durable state
  files (feature_list.json, claude-progress.md, init.sh), then run the fixed
  startup and end-of-session loop. Use when the user says "/harness", "init the
  harness", "start a session", "hand off", or when claude-progress.md or
  feature_list.json exists and a session starts or ends.
---

The repository is the system of record. Chat is not. State that must survive a session lives in files; a fresh session recovers it by reading them, not by guessing. Based on [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering).

## Init (once per repo, skip files that already exist)

Copy from `templates/` next to this file, then adapt — never leave placeholders:

1. `claude-progress.md` — session log + current verified state.
2. `feature_list.json` — every user-visible feature with `id`, `priority`, `status`, `verification` steps and `evidence`. Write real features from the repo's README/issues/code; all start `not_started`.
3. `init.sh` — one startup path: install, baseline verification, start command. Use the repo's real commands (detect `package.json`, `composer.json`, `bats`, `Makefile`). `chmod +x`.
4. Optional: `session-handoff.md`, `clean-state-checklist.md` when sessions are large.

Commit the four as one change. Once `claude-progress.md` or `feature_list.json` exists, the `SessionStart` hook prints the state and the `Stop` hook checks the handoff.

## Session start

1. `pwd` — confirm the repo root.
2. Read `claude-progress.md`, then `feature_list.json`.
3. `git log --oneline -5`.
4. `./init.sh` — then the baseline smoke/e2e path.
5. Baseline broken? Fix that first. No new work on a broken start.
6. Pick the highest-priority unfinished feature. Set it `in_progress`. One at a time.

## While working

- Stay inside the selected feature. A blocker may justify one narrow supporting fix.
- `passing` needs the feature's `verification` steps actually run, with evidence recorded (command + result, not "looks fine").
- Never reword, delete or weaken a feature or test to make it pass. Never loosen verification mid-feature.
- Declared done? Run the `harness-evaluator` agent: fresh context, tries to refute the claim.

## Session end

1. Update `claude-progress.md`: verified state, what ran, evidence, known risk, next best step.
2. Update `feature_list.json` statuses and evidence.
3. Walk `templates/clean-state-checklist.md`.
4. Commit once the repo is safe to resume. Next session must run `./init.sh` immediately, no manual repair.

## Boundaries

Do not invent features, evidence or verification results. Do not mark `passing` without a run. Do not hide unfinished work by editing the list.
