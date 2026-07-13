---
name: feature-ai-coding
description: AI coding skill pack (caveman terse-mode family + product-management workflow skills) plus the Claude Code GitHub Action for @claude mentions.
---

<!-- @format -->

# ai-coding

## Description

Use this feature when a repository wants a shared set of agent-agnostic coding skills, plus a GitHub Action that lets any contributor trigger Claude on an issue or pull request via an `@claude` mention.

## Commands

- `@claude <request>` in an issue comment, PR comment, PR review, or PR review comment — triggers the Claude Code GitHub Action.
- `/caveman`, `/caveman-commit`, `/caveman-review`, `/caveman-compress`, `/caveman-help` — terse-communication-mode skills.
- `/pm-research-synthesis`, `/pm-roadmap-brief`, `/pm-prd-draft`, `/pm-metrics-digest`, `/pm-release-notes` — product-management workflow skills.

## Use For

- Letting any AI coding agent that reads `.github/skills/` discover and use these skills.
- Giving maintainers a low-friction way to delegate issue/PR work to Claude via `@claude` mentions.

## Do Not Use For

- Repository-specific git workflow automation (use `githooks`/`gitutils`).
- Commit message conventions (use `commit-naming`).

## Agent Guidance

- Treat every `.github/skills/*/SKILL.md` file as an available skill regardless of which agent is running — none of them assume a specific agent's tool names.
- The `claude.yml` workflow requires an `ANTHROPIC_API_KEY` repository secret to function; do not assume it exists without checking.
- The `pm/*` skills are tool-agnostic: they read local files/folders or use the `gh` CLI by default, and only prefer an MCP connector (Notion, Linear, Drive, etc.) when one is already configured in the current session.
