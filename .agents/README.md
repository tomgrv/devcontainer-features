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
- **Claude Code** (`.claude/skills/`): installed at runtime by `npx skills` (see `src/ai-coding/stubs/.claude/hooks/install-skills.sh`), fetched directly from this repo's `.agents/skills/<name>` — no stub copy is shipped. It runs on devcontainer `postCreate` and on every Claude Code `SessionStart`, so it also covers claude.ai/code web/cloud sessions.

## Adding a new distributable skill

1. Write the real `SKILL.md` (and any sibling files) under `.agents/skills/<name>/`.
2. Add to `src/ai-coding/stubs/.agents/skills/<name>/` (same content — this copy backs the `.github/skills/` Copilot stub).
3. Symlink the Copilot stub:
    ```sh
    ln -s ../../.agents/skills/<name> src/ai-coding/stubs/.github/skills/<name>
    ```
4. Add `<name>` to the `SKILLS` list in `src/ai-coding/stubs/.claude/hooks/install-skills.sh` so Claude Code installs it too.
5. Symlink from root (dogfooding):
    ```sh
    ln -s ../../.agents/skills/<name> .github/skills/<name>
    ln -s ../../.agents/skills/<name> .claude/skills/<name>
    ```
6. `git add` all — git tracks symlinks as mode `120000`.
