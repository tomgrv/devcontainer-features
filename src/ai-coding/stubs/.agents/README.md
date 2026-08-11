<!-- @format -->

# `.agents/`

Single source of truth for every AI coding tool's configuration and guidance in this repo (Claude Code, GitHub Copilot, and any other agent that reads `.github/skills/`). Real files live here; every tool-specific conventional path is a symlink back into this directory.

**Always edit the file under `.agents/`, never a symlink.**

## Layout

| Path here        | Symlinked from                                      | Consumed by                                                               |
| ---------------- | --------------------------------------------------- | ------------------------------------------------------------------------- |
| `skills/<name>/` | `.github/skills/<name>` and `.claude/skills/<name>` | Copilot/agent-agnostic (`.github/`) · Claude Code Skill tool (`.claude/`) |

Skills not distributed to consumer repos (Claude Code-specific mechanisms) — `caveman-stats`, `cavecrew` — are in `.agents/skills/` only and symlinked into `.claude/skills/` but **not** into `.github/skills/` or `src/ai-coding/stubs/`.

## Adding a new distributable skill

1. Write the real `SKILL.md` (and any sibling files) under `.agents/skills/<name>/`.
2. Add to `src/ai-coding/stubs/.agents/skills/<name>/` (same content — the stubs are the distribution source).
3. Symlink from both conventional paths in stubs:
    ```sh
    ln -s ../../.agents/skills/<name> src/ai-coding/stubs/.github/skills/<name>
    ln -s ../../.agents/skills/<name> src/ai-coding/stubs/.claude/skills/<name>
    ```
4. Symlink from root (dogfooding):
    ```sh
    ln -s ../../.agents/skills/<name> .github/skills/<name>
    ln -s ../../.agents/skills/<name> .claude/skills/<name>
    ```
5. `git add` all — git tracks symlinks as mode `120000`.
