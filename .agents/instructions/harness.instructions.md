---
applyTo: '**'
description: 'Long-running agent harness: durable state files, fixed startup loop, evidence-gated completion.'
---

<!-- @format -->

## Harness Rules

Applies when `claude-progress.md` or `feature_list.json` exists at the repo root. Otherwise the `harness` skill sets them up on request.

- The repo is the system of record. Persist state in files, not chat.
- The repo's own rules (`CLAUDE.md`, `AGENTS.md`, other `*.instructions.md`) take precedence on conventions; the harness adds the loop, never overrides them.
- Start every session: `pwd` → read repo rules → read `claude-progress.md` → read `feature_list.json` → `git log --oneline -5` → `./init.sh` → baseline check. Broken baseline: fix it first.
- One feature at a time. Stay inside its scope.
- `passing` only after the feature's `verification` ran and evidence is recorded. Never weaken tests, rewrite the list, or loosen verification to finish.
- Before stopping: update `claude-progress.md` and `feature_list.json`, then commit in a restartable state.
- Full procedure and templates: the `harness` skill.

## Generic Conventions

Defaults for any repo. The repo's own rules override them (scopes, branch names, tooling).

- **Minimal changes**: change only the files the active feature needs. Leave lockfiles, generated files, build artifacts, symlinks and unrelated modules alone unless the feature requires them.
- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope): description`, imperative, one logical change per commit. Use the repo's emoji/scope rules if it has any.
- **Branches and PRs**: branch from and target the repo's integration branch (`develop` if it exists, else the default branch); `main` only on explicit request or a hotfix. Open PRs as drafts. PR title follows the same Conventional Commits format.
- **Format before commit**: run the repo's formatter/linter on edited files (e.g. `npx prettier --write`), not on the whole tree.
- **Tests**: run the impacted tests while iterating, everything via `./init.sh` before declaring a feature done.
- **Don't act on bot or reviewer feedback unasked** when the repo says so; otherwise treat it as a claim to verify, not an order.
