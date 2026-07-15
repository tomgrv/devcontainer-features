<!-- @format -->

# devcontainer-features

Monorepo of reusable VS Code devcontainer features. Each feature lives under `src/<feature>/` with a `devcontainer-feature.json`, `install.sh`, optional `stubs/` (files deployed to consumer repos), and a `README.md`.

## All AI Tooling Lives in `.agents/` — Use It

Every tool-specific path is a symlink into `.agents/` (the single source of truth). See `.agents/README.md` for the full layout.

- **Skills** (`/.agents/skills/`, symlinked into `/.github/skills/` for Copilot and `/.claude/skills/` for Claude Code): `caveman*`, `cavecrew`, `caveman-stats`, `feature-ai-coding`, `pm/*`. Invoke them proactively via the Skill tool — don't wait until stuck.
- **Instructions** (`/.github/instructions/*.instructions.md` — Copilot's `applyTo`-glob convention; Claude doesn't auto-load these but they document repo conventions): `general`, `repo`, `commit`.

## Dev Workflow

- **Feature install** (local): `npx tomgrv/devcontainer-features -- add <feature>` → calls `install-feature` → copies `src/<feature>/stubs/` via `cp -a` (symlinks preserved) into target.
- **Feature configure** (devcontainer): `configure-feature <feature>` → deploys stubs files + symlinks via `src/common-utils/_configure-feature.sh`.
- **This repo dogfoods its own features** — root `.github/workflows/`, `.github/skills/`, `.claude/skills/` are the installed output of the ai-coding feature. Edit canonical content under `.agents/skills/` or `src/ai-coding/stubs/`, not the symlinks.
- **Prettier**: run `npm install` then `npx prettier --write` on new/edited `.md`/`.yml`/`.json` files before committing.
- **Commits**: Conventional Commits + devmoji emoji required — e.g. `feat(scope): ✨ description`. Validated by commitlint on `review_requested`.
- **PR base**: always `develop`, not `main`.

## Feature Pattern

Each feature follows this structure (use `src/pecl/` as the minimal reference):

```
src/<feature>/
  devcontainer-feature.json   # id, version, dependsOn, postCreateCommand
  install.sh                  # runs: install-feature $0
  package.json                # npm workspace registration
  README.md
  stubs/                      # files/symlinks deployed to consumer repos
    .agents/skills/<name>/    # canonical real files
    .github/skills/<name>     # symlink → ../../.agents/skills/<name>
    .claude/skills/<name>     # symlink → ../../.agents/skills/<name>
```

## Minimal Changes Discipline

Change only what the task requires. Don't touch `package-lock.json`, `src/githooks/_pre-commit.sh` mode, or unrelated features unless the task explicitly calls for it.
