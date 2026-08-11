<!-- @format -->

# `.agents/`

Single source of truth for every AI coding tool's configuration and guidance in this repo (Claude Code, GitHub Copilot, and any other agent that reads `.github/skills/`). Real files live here; every tool-specific conventional path is a symlink back into this directory.

**Always edit the file under `.agents/`, never a symlink.**

## Layout

| Path here        | Symlinked from          | Consumed by                   |
| ---------------- | ----------------------- | ----------------------------- |
| `skills/<name>/` | `.github/skills/<name>` | Copilot/agent-agnostic agents |

Claude Code and GitHub Copilot do not read a symlinked copy here. `.claude/hooks/install-skills.sh` fetches these same skills at runtime, straight from `tomgrv/devcontainer-features:.agents/skills/`, via [`npx skills`](https://github.com/vercel-labs/skills) — run on devcontainer `postCreate` and on every Claude Code `SessionStart` (see `.claude/settings.json`).

## `registry.json`

`.agents/registry.json` is the dedicated manifest driving `install-skills.sh` — it lists:

- `skills` — names under `.agents/skills/` to fetch (e.g. `caveman`, `pm/prd-draft`).
- `agents` — `npx skills` target ids to install each skill for (`claude-code`, `github-copilot`).
- `plugins` — Claude Code plugin-marketplace entries (`caveman`, `ponytail`) already enabled via `.claude/settings.json`'s `enabledPlugins`/`extraKnownMarketplaces`. Listed here for reference only — `install-skills.sh` does not install plugins, Claude Code does that itself from `settings.json`.

## Adding a new skill

Edit `.agents/skills/<name>/` upstream in `tomgrv/devcontainer-features` (this directory is deployed read-only into consumer repos) — see that repo's `.agents/README.md`.
