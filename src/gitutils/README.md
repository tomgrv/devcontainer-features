<!-- @format -->

# Git Utils

This feature provides a set of utilities for working with Git repositories.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:7": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add gitutils
```

## Functional Coverage

Installs a collection of Git utilities.
Installs the git-flow extension and sets up Git configuration to use it.
Adds shortcuts to the git command for easier use of git-flow commands.

## GitFlow

Additionally, the feature installs the [git-flow](https://github.com/nvie/gitflow) extension and sets up the Git configuration to use it.

### Install step

`git-flow` (the `gitflow-avh` package) is installed as an OS package by `install-gitflow.sh`, which runs once when the feature is installed — primarily satisfied by the `common-utils` feature dependency already, with a package-manager-detecting fallback if it's still missing.

### Configure step

`configure-feature gitutils` (run automatically from `postCreateCommand`, and re-runnable at any time from the repository root) runs `configure-gitflow.sh`, which non-interactively runs `git flow init -d -f` with the following branch/prefix scheme:

| Prompt                                | Value                  |
| ------------------------------------- | ---------------------- |
| Branch for production releases        | `main`                 |
| Branch for "next release" integration | `develop`              |
| Feature branches prefix               | `feature/`             |
| Bugfix branches prefix                | `bugfix/`              |
| Release branches prefix               | `release/`             |
| Hotfix branches prefix                | `hotfix/`              |
| Support branches prefix               | `support/`             |
| Version tag prefix                    | `v`                    |
| Hooks and filters directory           | `.git/hooks` (default) |

Each value can be overridden by exporting the matching environment variable before `configure-gitflow.sh` runs: `GITFLOW_MASTER_BRANCH`, `GITFLOW_DEVELOP_BRANCH`, `GITFLOW_FEATURE_PREFIX`, `GITFLOW_BUGFIX_PREFIX`, `GITFLOW_RELEASE_PREFIX`, `GITFLOW_HOTFIX_PREFIX`, `GITFLOW_SUPPORT_PREFIX`, `GITFLOW_VERSIONTAG_PREFIX`.

Shortcuts are also added to the `git` command to make it easier to use the `git-flow` commands:

- `git beta` is a shortcut for `git flow release start`
- `git hfix` is a shortcut for `git flow hotfix start`
- `git prod` is a shortcut for `git flow release finish` and `git flow hotfix finish`

These shortcuts work in conjunction with the `gitversion` utility to automatically update the version number of the application.

## Interactive Utilities

The feature includes the following interactive utilities:

- `git align` - Align the current branch with its remote counterpart.
- `git degit <repository> [directory]` - Download and extract a repository from GitHub, GitLab, or Bitbucket.
- `git fix date [options] [<commit>]` - Fix commit dates and times in git history. Options include rescheduling commits on specific days of week outside certain time ranges.
- `git fix blanks [-d]` - Discard tracked text-file changes when differences are only blanks and quote/slash swaps.
- `git fix message -m <message> [--force|<commit>]` - Rewrite the commit message of a specific commit.
- `git fix secrets -g <glob> -s <secret> [-r <replace>] [-f] [-p] [-d] [-m] [-t] [<commit>]` - Redact a secret from files matching a glob pattern (and optionally commit messages and tag annotations) across all git history, replacing it with `****` (or `-r <replace>`).
- `git fix up [--force|<commit>]` - Amend the specified commit with current changes and rebase (alias: `git fu`).
- `git forall <command>` - Execute a command for all files in the repository.
- `git getcommit [--force|<commit>]` - Get the commit to fixup. Pass `0` as `<commit>` to resolve to the very first commit in history.
- `git integrate` - Integrate modifications from the remote repository.
- `git release-beta` - Start a new release branch using Git Flow.
- `git release-hotfix` - Start a new hotfix branch using Git Flow.
- `git release-prod` - Finish a release or hotfix branch using Git Flow.
- `git fix rights` - Set permissions for files and directories according to best practices.
- `git unset <prefix> [--local|--global|--system]` - Unset all Git config keys starting with the given prefix.

## Aliases

The following aliases are provided to enhance your Git workflow:

- `git amend` - Amend the last commit with the current changes.
- `git beta` - Start a new release branch using Git Flow.
- `git cleanup` - Stash all changes, clean the working directory, and apply the stash.
- `git co <message>` - Commit with the provided message.
- `git conflict` - List files with merge conflicts.
- `git continue` - Continue the rebase process after resolving conflicts.
- `git fixable` - List commits that can be fixed up.
- `git forceable` - List commits that can be force-pushed.
- `git go <message>` - Commit all changes with the provided message.
- `git hfix` - Start a new hotfix branch using Git Flow.
- `git histo` - Show the commit history from the last merge.
- `git ignore <file>` - Add the specified file to `.gitignore` and remove it from the index.
- `git initFrom <repo> <dir>` - Clone a repository and set up branches.
- `git isChanged <file>` - Check if the specified file has changed.
- `git isDirty <file>` - Check if the specified file has uncommitted changes.
- `git isFixup` - Check if the last commit is a fixup commit.
- `git isRebase` - Check if a rebase is in progress.
- `git pn` - Push without running pre-push hooks.
- `git prod` - Finish a release or hotfix branch using Git Flow.
- `git renameTag <old> <new>` - Rename a tag.
- `git stack` - Amend the last commit without changing the commit message.
- `git sync` - Fetch and merge changes from the upstream branch.
- `git undo` - Undo the last commit, keeping the changes in the working directory.

## Customizations

The feature also includes the following VS Code customizations:

- Extensions:
    - `donjayamanne.githistory`
    - `tomblind.scm-buttons-vscode`
    - `mhutchie.git-graph`
    - `arturock.gitstash`
    - `github.copilot`
    - `github.copilot-chat`
    - `github.vscode-github-actions`
    - `gitHub.vscode-pull-request-github`
    - `github.codespaces`
    - `waderyan.gitblame`

- Settings:
    - `explorer.excludeGitIgnore`: `true`
    - `git.autorefresh`: `true`

## Git Fix Date

The `git fix date` command allows you to correct commit dates and times in your git history. It provides advanced options to reschedule commits that fall outside specific time ranges for certain days of the week, while maintaining the sequential order of commits.

### Usage

```bash
# Basic usage with default values (reschedule Mon-Fri 08:00-17:00 to 06:00/20:00)
# The command will display a plan and ask for confirmation
git fix date -f [ < commit-sha > ]

# Dry-run mode to preview changes without applying them (no confirmation needed)
git fix date -d [ < commit-sha > ]

# Reschedule commits with custom options
git fix date -r < days > -s < start > -e < end > -b < before > -a < after > [ < commit-sha > ]
```

### Options

- `-f` - Force mode: allow overwriting pushed history
- `-p` - Push changes after rewriting history
- `-d` - Dry-run mode: display change plan without applying changes or asking for confirmation
- `-r <days>` - Days of week to reschedule (default: `1,2,3,4,5` for Mon-Fri; 0=Sunday, 6=Saturday)
- `-s <start>` - Start time for rescheduling (default: `08:00`, HH:MM format)
- `-e <end>` - End time for rescheduling (default: `17:00`, HH:MM format)
- `-b <before>` - Time to move first half commits to (default: `06:00`, HH:MM format)
- `-a <after>` - Time to move second half commits to (default: `20:00`, HH:MM format)

### Default Behavior

When run without options, the command will:

- Display a change plan showing all commits that will be modified
- Ask for confirmation before proceeding
- Reschedule commits on weekdays (Monday-Friday)
- Target commits between 08:00 and 17:00
- Move first half (08:00-12:30) to 06:00
- Move second half (12:30-17:00) to 20:00

### Examples

#### Example 1: Preview changes with dry-run mode

```bash
git fix date -d
```

Output:

```
=== Change Plan ===

a1b2c3d | 2024-03-04 09:00:00 → 2024-03-04 06:00:00 | Monday morning work
e4f5g6h | 2024-03-04 14:00:00 → 2024-03-04 20:00:00 | Monday afternoon work

=== End of Change Plan ===

Dry run complete. No changes were made.
```

#### Example 2: Apply default weekday rescheduling with confirmation

```bash
git fix date -f
```

The command will display the change plan and prompt:

```
This will rewrite git history. Make sure you understand the consequences.
Do you want to proceed? (y/N)
```

#### Example 3: Reschedule Sunday commits

Reschedule all Sunday commits between 8:00 and 20:00:

- Commits in the first half (8:00-14:00) will be moved to 7:30 on the same day
- Commits in the second half (14:00-20:00) will be moved to 20:30 on the same day

```bash
git fix date -f -r 0 -s 08:00 -e 20:00 -b 07:30 -a 20:30
```

### Important Notes

- The sequential order of commits is always preserved
- Only the time is modified, never the date
- The command uses `git filter-branch` to rewrite history
- Use `-f` flag carefully as it allows overwriting pushed history

## Git Fix Secrets

The `git fix secrets` command searches all git history (all branches and tags, or from a given commit) for files matching a glob pattern, and replaces every occurrence of a specified secret value with `****` (or a custom string via `-r`). It can optionally also redact the secret from commit messages (`-m`) and annotated tag messages (`-t`). If no commit is specified, `git getcommit` is used to resolve it (prompting interactively unless `-f`/forceable/fixable listing resolves it); pass `0` as the commit to start from the very first commit in history.

### Usage

```bash
# Search and preview matching commits/files without rewriting history
git fix secrets -d -g "**/*.env" -s "my-secret-value"

# Also preview matches in commit messages and tag annotations
git fix secrets -d -m -t -g "**/*.env" -s "my-secret-value"

# Redact the secret from history (asks for confirmation)
git fix secrets -g "**/*.env" -s "my-secret-value"

# Redact from files, commit messages and tag annotations, starting from the very first commit
git fix secrets -m -t -g "**/*.env" -s "my-secret-value" 0

# Redact and push the rewritten history
git fix secrets -p -g "**/*.env" -s "my-secret-value"

# Use a custom replacement string instead of the default ****
git fix secrets -g "**/*.env" -s "my-secret-value" -r "[REDACTED]"
```

### Options

- `-f` - Force mode: allow overwriting pushed history
- `-p` - Push changes after rewriting history
- `-d` - Dry-run mode: list matching commits/files without applying changes or asking for confirmation
- `-g <glob>` - Glob pattern of files to search (e.g. `**/*.env`, `config/*.json`)
- `-s <secret>` - Literal secret value to redact
- `-r <replace>` - Replacement string (default: `****`)
- `-m` - Also redact the secret from commit messages
- `-t` - Also redact the secret from annotated tag messages
- `<commit>` - Optional commit to start rewriting from; use `0` for the very first commit, or omit to be prompted via `git getcommit` (defaults to the entire history there)

### Important Notes

- The secret is matched and replaced literally (not as a regular expression).
- Binary files are skipped.
- The command uses `git filter-branch` to rewrite history; only shell tools (`sed`, `grep`) are used, no external interpreter is required.
- Use `-f` flag carefully as it allows overwriting pushed history.
- Rewriting history changes commit hashes; anyone with a clone of the repository will need to re-clone or hard-reset after a `-p` push. Rotate the leaked secret as well — redacting history does not undo any exposure that already happened.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
