<!-- @format -->

# `.agents/`

Single source of truth for every AI coding tool's configuration and guidance in this repo (Claude Code, GitHub Copilot, and any other agent that reads `.github/skills/`). Real files live here; every tool-specific conventional path is a symlink back into this directory.

**Always edit the file under `.agents/`, never a symlink.**

## Layout

| Path here        | Symlinked from                                                                                                                        | Consumed by |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `skills/<name>/` | `.github/skills/<name>` (Copilot/agent-agnostic) and, in this repo only, `.claude/skills/<name>` (Claude Code Skill tool, dogfooding) |

Skills not distributed to consumer repos (Claude Code-specific mechanisms) — `caveman-stats`, `cavecrew` — are in `.agents/skills/` only and symlinked into `.claude/skills/` but **not** into `.github/skills/` or `src/ai-coding/stubs/`.

Consumer repos get skills two different ways:

- **Copilot/agent-agnostic** (`.github/skills/`): file stubs, copied by `configure-feature ai-coding` from `src/ai-coding/stubs/.github/skills/`.
- **Claude Code and GitHub Copilot** (live install): fetched at runtime by `npx skills` (see `src/ai-coding/stubs/.claude/hooks/configure-skills.sh`), straight from this repo's `.agents/skills/<name>` — no `.claude/skills/`/`~/.copilot/skills/` stub copy is shipped. Runs on devcontainer `postCreate` and on every Claude Code `SessionStart` (`configure-skills.sh sync`), so it also covers claude.ai/code web/cloud sessions. Which skills get installed for which agents is driven by the root `ai-coding.json` manifest — the dedicated manifest for skills, plugins, and target agents. Any other feature that `dependsOn` `ai-coding` and ships its own `stubs/ai-coding.json` fragment gets merged into the same root file (see `.agents/README.md`'s "Adding a new plugin" and the ai-coding feature README).
- **Claude Code plugins** (`caveman`, `ponytail`): declared in `ai-coding.json`'s `plugins` array and kept live in `.claude/settings.json`'s `enabledPlugins`/`extraKnownMarketplaces` by `configure-skills.sh sync` — Claude Code installs and enables these itself once declared there, no manual mirroring needed.

## Adding a new distributable skill

1. Write the real `SKILL.md` (and any sibling files) under `.agents/skills/<name>/`.
2. Add to `src/ai-coding/stubs/.agents/skills/<name>/` (same content — this copy backs the `.github/skills/` Copilot stub).
3. Symlink the Copilot stub:
    ```sh
    ln -s ../../.agents/skills/<name> src/ai-coding/stubs/.github/skills/<name>
    ```
4. Add `<name>` to the `skills` array in `src/ai-coding/stubs/ai-coding.json` so `configure-skills.sh sync` installs it for Claude Code and GitHub Copilot too.
5. Symlink from root (dogfooding):
    ```sh
    ln -s ../../.agents/skills/<name> .github/skills/<name>
    ln -s ../../.agents/skills/<name> .claude/skills/<name>
    ```
6. `git add` all — git tracks symlinks as mode `120000`.

## Adding a new plugin

Add an entry to `src/ai-coding/stubs/ai-coding.json`'s `plugins` array (`name`, `marketplace`, `url`). `configure-skills.sh sync` merges it into `.claude/settings.json`'s `enabledPlugins`/`extraKnownMarketplaces` on the next devcontainer `postCreate` or Claude Code `SessionStart` — no manual settings edit needed.
| Path here        | Symlinked from          | Consumed by                   |
| ---------------- | ----------------------- | ----------------------------- |
| `skills/<name>/` | `.github/skills/<name>` | Copilot/agent-agnostic agents |
Claude Code and GitHub Copilot do not read a symlinked copy here. `.claude/hooks/configure-skills.sh sync` fetches these same skills at runtime, straight from `tomgrv/devcontainer-features:.agents/skills/`, via [`npx skills`](https://github.com/vercel-labs/skills) — run on devcontainer `postCreate` and on every Claude Code `SessionStart` (see `.claude/settings.json`).
## `ai-coding.json`
Root `ai-coding.json` is the dedicated manifest driving `configure-skills.sh sync` — it lists:
- `skills` — names under `.agents/skills/` to fetch (e.g. `caveman`, `pm/prd-draft`).
- `agents` — `npx skills` target ids to install each skill for (`claude-code`, `github-copilot`).
- `plugins` — Claude Code plugin-marketplace entries (`caveman`, `ponytail`), kept live in `.claude/settings.json`'s `enabledPlugins`/`extraKnownMarketplaces` by `configure-skills.sh sync`.
Any other installed feature that `dependsOn` `ai-coding` and ships its own `ai-coding.json` stub fragment gets it merged into this same root file (array fields are unioned) — so its skills/agents/plugins install the same way, no extra script needed beyond calling `.claude/hooks/configure-skills.sh sync` from its own `postCreateCommand`.
Edit `.agents/skills/<name>/` upstream in `tomgrv/devcontainer-features` (this directory is deployed read-only into consumer repos) — see that repo's `.agents/README.md`.
