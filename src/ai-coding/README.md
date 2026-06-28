<!-- @format -->

# AI Coding Feature

This feature adds agent-agnostic AI coding skills (`.github/skills/`) and the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) for `@claude` mentions on issues and pull requests.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/ai-coding:1": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add ai-coding
```

## What gets installed

- `.github/workflows/claude.yml` — runs Claude on `@claude` mentions in issue comments, PR comments, PR reviews, PR review comments, and new issues.
- `.github/skills/caveman*` — ultra-compressed communication mode skills (terse mode, commit messages, PR reviews, markdown compression, help reference).
- `.github/skills/pm/*` — product-management workflow skills: research synthesis, roadmap prioritization brief, PRD drafting, metrics digest, release notes generation.

These skills use the `name`/`description` frontmatter convention in `.github/skills/<name>/SKILL.md`, so they're discoverable by any AI coding agent that reads that convention, not just Claude.

## Setup

After installing, add a repository secret named `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions → New repository secret) containing a valid Anthropic API key, so the `claude.yml` workflow can authenticate. Without this secret, `@claude` mentions will not trigger a response.
