<!-- @format -->

# AI Coding Feature

This feature adds agent-agnostic AI coding skills and the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) for `@claude` mentions on issues and pull requests. Skills are canonically stored under `.agents/skills/` and symlinked into both `.github/skills/` (for Copilot and any agent-agnostic agent) and `.claude/skills/` (for Claude Code's Skill tool).

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
- `.agents/skills/caveman*` — ultra-compressed communication mode skills (terse mode, commit messages, PR reviews, markdown compression, help reference). Symlinked from `.github/skills/` and `.claude/skills/`.
- `.agents/skills/pm/*` — product-management workflow skills: research synthesis, roadmap prioritization brief, PRD drafting, metrics digest, release notes generation. Symlinked from `.github/skills/` and `.claude/skills/`.
- `.agents/skills/feature-ai-coding/` — self-doc skill for this feature.
- `CLAUDE.md` — orientation file for Claude Code.
- `.agents/README.md` — documents the `.agents/` layout.

Skills follow the `name`/`description` frontmatter convention in `SKILL.md`. `.agents/` is the single source of truth; every agent reads the same content via its own conventional path.

## Setup

After installing, add a repository secret named `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions → New repository secret) containing a valid Anthropic API key, so the `claude.yml` workflow can authenticate. Without this secret, `@claude` mentions will not trigger a response.
