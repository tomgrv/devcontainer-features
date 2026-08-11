<!-- @format -->

# AI Coding

This repo has the `ai-coding` devcontainer feature installed. Read `.agents/README.md` for the AI tooling layout.

## Skills — use them

Canonical skill content lives at `tomgrv/devcontainer-features:.agents/skills/` and is symlinked into `.github/skills/` for agent-agnostic agents. Claude Code and GitHub Copilot do **not** get a stub copy: `.claude/hooks/_skills.sh sync` fetches the same skills straight from that repo via `npx skills`, run on devcontainer `postCreate` and on every Claude Code `SessionStart` (covers claude.ai/code web/cloud sessions too). Which skills get installed, for which agents, plus this feature's Claude Code plugins (`caveman`, `ponytail`, kept live in `.claude/settings.json` by the same sync), are all listed in root `ai-coding.json` — the single manifest for skills/plugins/agents, mergeable with fragments from other features that depend on `ai-coding`. Skills are auto-discoverable once installed — invoke them proactively per their descriptions.

Key skills:

- **`caveman`** / `caveman-commit` / `caveman-compress` / `caveman-help` / `caveman-review` — ultra-compressed terse communication mode and related utilities.
- **`pm/*`** (`pm-research-synthesis`, `pm-roadmap-brief`, `pm-prd-draft`, `pm-metrics-digest`, `pm-release-notes`) — product-management workflow skills.
- **`feature-ai-coding`** — this feature's own self-doc skill.

## GitHub Action — `@claude`

The `claude.yml` workflow responds to `@claude` mentions in issue/PR comments, PR reviews, and new issues. Requires a repository secret `ANTHROPIC_API_KEY`.

## Minimal Changes Discipline

Change only what the task requires. Don't touch unrelated config files or dependencies unless explicitly asked.
