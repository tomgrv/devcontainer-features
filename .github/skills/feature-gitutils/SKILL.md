<!-- @format -->

# gitutils

## Description

Use this feature for advanced Git operations, interactive repository maintenance, and git-flow shortcuts.

## Commands

- `git align` - Align current branch with its remote tracking branch.
- `git integrate` - Integrate remote modifications into current branch.
- `git fixup [--force|<commit>]` - Amend a target commit and rebase history.
- `git getcommit [--force|<commit>]` - Resolve/select commit target for fixup.
- `git fix date [options] [<commit>]` - Rewrite commit times with scheduling rules.
- `git forall <command>` - Execute a command for repository files.
- `git release-beta` - Start a Git Flow release branch.
- `git release-hotfix` - Start a Git Flow hotfix branch.
- `git release-prod` - Finish release/hotfix flow for production.
- `git unset <prefix> [--local|--global|--system]` - Remove git config keys by prefix.
- `git autorebase [-f] [-p] [-a] [-n] [-s strategy] [-o onto] [-b branch] [sha]` - Non-interactive rebase with automatic conflict resolution.

## GitHub Actions

### `.github/actions/rebase`

A self-contained composite action that rebases a pull request branch onto its base.
Implemented in pure `sh` + `git` + `gh` CLI — no external action dependencies.

**Inputs:**

| Input | Default | Description |
|---|---|---|
| `autosquash` | `false` | Apply `--autosquash` (squash!/fixup! commits) |
| `token` | `github.token` | GitHub token with repo write access |

**Trigger:** Called from `.github/workflows/rebase-pr.yml` when a PR comment contains `/rebase` or `/autosquash`.

**To reuse in another workflow:**
```yaml
- uses: ./.github/actions/rebase
  with:
    autosquash: 'true'
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Key behaviours:**
- Resolves PR metadata (head/base branches, fork URL) via `gh pr view`.
- Skips if the branch is already up-to-date (no unnecessary force-push).
- Supports cross-fork PRs by adding a temporary `head_fork` remote.
- Uses `--force-with-lease` to avoid clobbering concurrent pushes.
- Respects `--autosquash` when `fixup!`/`squash!` commits are present.

## Use For

- Branch/rebase alignment and integration tasks.
- Commit cleanup/fixup workflows.
- Release branch shortcuts (`beta`, `hfix`, `prod`).
- Batch repository operations and helper aliases.
- Automated PR rebasing via GitHub Actions comment triggers.

## Do Not Use For

- Commit policy enforcement hooks (use `githooks`).
- Semantic version calculation (use `gitversion`).

## Agent Guidance

- Prefer built-in aliases/utilities before crafting raw multi-step Git commands.
- For history-rewrite actions, use explicit/force flags only when requested.
- Keep operations scoped and reversible where possible.
- When creating GitHub Actions that perform rebases, use `.github/actions/rebase` instead of third-party actions.
- The composite action shell script (`rebase.sh`) follows the same `sh` conventions as the other scripts in this feature — POSIX-compatible, `set -eu`, `gh` CLI for GitHub API calls.
