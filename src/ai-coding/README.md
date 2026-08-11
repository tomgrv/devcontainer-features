<!-- @format -->

# AI Coding Feature

This feature adds agent-agnostic AI coding skills and the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) for `@claude` mentions on issues and pull requests. Skills are canonically stored under `.agents/skills/` in this repo. Copilot/agent-agnostic agents get them as file stubs symlinked into `.github/skills/`; Claude Code installs them itself at runtime via [`npx skills`](https://github.com/vercel-labs/skills), so no `.claude/skills/` copy is committed to consumer repos.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/ai-coding:7": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add ai-coding
```

## What gets installed

- `.github/workflows/claude.yml` — runs Claude on `@claude` mentions in issue comments, PR comments, PR reviews, PR review comments, and new issues.
- `.agents/skills/caveman*` — ultra-compressed communication mode skills (terse mode, commit messages, PR reviews, markdown compression, help reference). Symlinked from `.github/skills/`; installed into `.claude/skills/` at runtime.
- `.agents/skills/pm/*` — product-management workflow skills: research synthesis, roadmap prioritization brief, PRD drafting, metrics digest, release notes generation. Symlinked from `.github/skills/`; installed into `.claude/skills/` at runtime.
- `.agents/skills/feature-ai-coding/` — self-doc skill for this feature.
- `.claude/hooks/install-skills.sh` — installs the skills above into `.claude/skills/` via `npx skills`, fetched straight from `tomgrv/devcontainer-features:.agents/skills/`. Runs on devcontainer `postCreate` (`configure-skills.sh`) and on every Claude Code `SessionStart` — so it also covers claude.ai/code web/cloud sessions, which never run devcontainer `postCreate`.
- `CLAUDE.md` — orientation file for Claude Code.
- `.agents/README.md` — documents the `.agents/` layout.

Skills follow the `name`/`description` frontmatter convention in `SKILL.md`. `.agents/` is the single source of truth; Copilot reads a stub copy, Claude Code fetches the same content live.

## Setup

After installing, add a repository secret named `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions → New repository secret) containing a valid Anthropic API key, so the `claude.yml` workflow can authenticate. Without this secret, `@claude` mentions will not trigger a response.

`.claude/hooks/install-skills.sh` requires `npx` (Node.js) on `PATH`; if it's missing the hook logs a warning and exits cleanly rather than failing the session.
