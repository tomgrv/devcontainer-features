<!-- @format -->

# AI Coding Feature

This feature adds agent-agnostic AI coding skills and the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) for `@claude` mentions on issues and pull requests. Skills are canonically stored under `.agents/skills/` in this repo. Copilot/agent-agnostic agents get them as file stubs symlinked into `.github/skills/`; both Claude Code and GitHub Copilot also get them installed live at runtime via [`npx skills`](https://github.com/vercel-labs/skills) (no `.claude/skills/` or `~/.copilot/skills/` copy is committed to consumer repos). Claude Code additionally gets a couple of ready-made plugins (`caveman`, `ponytail`) enabled via its own plugin-marketplace mechanism. All three — skills, plugins, and target agents — are listed in one manifest at the consumer repo root: `ai-coding.json`.

Other features can opt into skills too: `dependsOn` this feature, ship a `stubs/ai-coding.json` fragment with their own `skills`/`agents`/`plugins`, and call `.claude/hooks/configure-skills.sh sync` from their own `postCreateCommand`. `configure-feature`'s stub deployment merges every feature's `ai-coding.json` fragment (array fields are unioned) into one root file.

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

## Quick Install — npm

```sh
npm install --save-dev @tomgrv-devcontainer-features/ai-coding
```

## What gets installed

- `.github/workflows/claude.yml` — runs Claude on `@claude` mentions in issue comments, PR comments, PR reviews, PR review comments, and new issues.
- `.agents/skills/caveman*` — ultra-compressed communication mode skills (terse mode, commit messages, PR reviews, markdown compression, help reference). Symlinked from `.github/skills/`; installed live for Claude Code and GitHub Copilot.
- `.agents/skills/pm/*` — product-management workflow skills: research synthesis, roadmap prioritization brief, PRD drafting, metrics digest, release notes generation. Symlinked from `.github/skills/`; installed live for Claude Code and GitHub Copilot.
- `.agents/skills/feature-ai-coding/` — self-doc skill for this feature.
- `ai-coding.json` (repo root) — the dedicated manifest listing everything installed: `skills` (names under `.agents/skills/`), `agents` (`npx skills` target ids — `claude-code`, `github-copilot`), and `plugins` (Claude Code plugin-marketplace entries — name, marketplace, git URL). Add or drop a skill/agent/plugin here, not in the scripts. Other features that `dependsOn` `ai-coding` can ship their own `stubs/ai-coding.json` fragment — `configure-feature`'s generic JSON-stub merge unions it into this same root file.
- `.claude/hooks/configure-skills.sh` — the `npx skills` wrapper. `configure-skills.sh sync` reads root `ai-coding.json` and, for each skill, runs `npx skills add tomgrv/devcontainer-features/.agents/skills/<name> -a <agent> ... -y` for every listed agent, then merges each declared plugin into `.claude/settings.json`'s `enabledPlugins`/`extraKnownMarketplaces` (the settings file Claude Code reads to enable plugins). Runs on devcontainer `postCreate` (`configure-skills.sh`) and on every Claude Code `SessionStart` — so it also covers claude.ai/code web/cloud sessions, which never run devcontainer `postCreate`.
- `.claude/settings.json` — seeds `ai-coding.json`'s `plugins` (`caveman`, `ponytail`) via `enabledPlugins`/`extraKnownMarketplaces`; kept in sync by `configure-skills.sh sync` as plugins are added/removed.
- `CLAUDE.md` — orientation file for Claude Code.
- `.agents/README.md` — documents the `.agents/` layout.

Skills follow the `name`/`description` frontmatter convention in `SKILL.md`. `.agents/` is the single source of truth; Copilot reads a stub copy, Claude Code and GitHub Copilot also fetch the same content live via `npx skills`.

## Setup

After installing, add a repository secret named `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions → New repository secret) containing a valid Anthropic API key, so the `claude.yml` workflow can authenticate. Without this secret, `@claude` mentions will not trigger a response.

`.claude/hooks/configure-skills.sh` requires `jq` on `PATH` (and `npx`/Node.js for the skills-install step); if either is missing, or root `ai-coding.json` isn't found, it logs a warning and exits cleanly rather than failing the session.
