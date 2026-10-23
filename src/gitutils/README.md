<!-- @format -->

# Git Utils

This feature provides a set of utilities for working with Git repositories.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:11": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add gitutils
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gitutils
```

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-gitutils
```

## Functional Coverage

Installs a collection of Git utilities.
Installs the git-flow extension and sets up Git configuration to use it.
Adds shortcuts to the git command for easier use of git-flow commands.

The utilities themselves live in [`tomgrv/scripts`](https://github.com/tomgrv/scripts#git-utilities)
(one source of truth, shared with every other `tomgrv`/`perspikapps` repo)
and are pulled in via `zz-use` at install time — this feature owns the
alias/config wiring and the git-flow install/configure lifecycle, not the
script implementations.

## GitFlow

Additionally, the feature installs the [git-flow](https://github.com/nvie/gitflow) extension and sets up the Git configuration to use it.

### Install step

`git-flow` (the `gitflow-avh` package) is installed as an OS package by `install-gitflow.sh`, which runs once when the feature is installed — primarily satisfied by the `common-utils` feature dependency already, with a package-manager-detecting fallback if it's still missing.

### Configure step

`feature-configure gitutils` (run automatically from `postCreateCommand`, and re-runnable at any time from the repository root) runs `configure-gitflow.sh`, which non-interactively runs `git flow init -d -f` with the following branch/prefix scheme:

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

If `main`/`develop` don't exist locally but a matching `origin/main`/`origin/develop` does (e.g. a fresh clone), `configure-gitflow.sh` checks that branch out rather than creating an orphan branch, so existing history is preserved.

`feature-configure gitutils` also runs `configure-knownhosts.sh`, which seeds `~/.ssh/known_hosts` with `github.com`'s key via `ssh-keyscan`. `openssh-client` (providing `ssh-keyscan`) is not a hard dependency of this feature — if it isn't installed, the script exits cleanly with no error and no known_hosts changes.

Shortcuts are also added to the `git` command to make it easier to use the `git-flow` commands:

- `git beta` is a shortcut for `git flow release start`
- `git hfix` is a shortcut for `git flow hotfix start`
- `git prod` is a shortcut for `git flow release finish` and `git flow hotfix finish`

These shortcuts work in conjunction with the `gitversion` utility to automatically update the version number of the application.

## Merge Drivers

`.gitattributes` marks `*.json` and `*.yaml`/`*.yml` with `merge=json`/`merge=yaml`,
but a driver name is only meaningful once registered in Git config. The
`configure-mergedrivers.sh` lifecycle script registers both, at repo scope:

```
git config merge.json.driver 'json-merge %A %B'
git config merge.yaml.driver 'yaml-merge %A %B'
```

With these registered, `git merge`/`git rebase`/`git cherry-pick` resolve
conflicts on JSON/YAML files by recursively merging objects and
deduping/unioning arrays (via [`json-merge`/`yaml-merge`](https://github.com/tomgrv/scripts))
instead of falling back to a line-based 3-way merge.

## Release Flow (CI)

Consumer repos get one deployed workflow under `.github/workflows/`:

- `release-prod.yml` — the production release entry point, via `tomgrv/actions/release-promote`, which drives the same `git-release-beta`/`git-release-prod` flow (`tomgrv/scripts`) exposed above as the `git beta`/`git prod` aliases.

Agent guidance for downstream repos using this feature:

- Always open pull requests with base `develop`, never `main`.
- Never push or open a PR directly against `main` — production releases go out only through the `release-prod` workflow.
- Trigger `release-prod` with the `gh-prod` command (a thin `gh workflow run release-prod.yml` wrapper) or via `workflow_dispatch` in the GitHub UI.

## Interactive Utilities

The feature includes the following interactive utilities:

- `git align` - Align the current branch with its remote counterpart.
- `git degit <repository> [directory]` - Download and extract a repository from GitHub, GitLab, or Bitbucket.
- `git fix date [options] [<commit>]` - Fix commit dates and times in git history. Options include rescheduling commits on specific days of week outside certain time ranges.
- `git fix blanks [-d]` - Discard tracked text-file changes when differences are only whitespace, blanks, and quote/slash swaps.
- `git fix message -m <message> [--force|<commit>]` - Rewrite the commit message of a specific commit.
- `git fix orphans [-p] [-x <prefix>] [<remote>]` - List (or, with `-p`, rename on the remote) the branches that do not follow the gitflow config and have no pull request, prefixing them with `orphan/`. Does nothing when no gitflow config is defined. The `manage-orphan-branches` workflow runs it weekly.
- `git fix prune [<remote>]` - Prune remote-tracking references that no longer exist on the remote (defaults to all remotes). Runs automatically on `postStartCommand`.
- `git fix secrets -g <glob> -s <secret> [-r <replace>] [-f] [-p] [-d] [-m] [-t] [<commit>]` - Redact a secret from files matching a glob pattern (and optionally commit messages and tag annotations) across all git history, replacing it with `****` (or `-r <replace>`).
- `git fix up [--force|<commit>]` - Amend the specified commit with current changes and rebase (alias: `git fu`).
- `git forall <command>` - Execute a command for all files in the repository.
- `git getcommit [--force|<commit>]` - Get the commit to fixup. Pass `0` as `<commit>` to resolve to the very first commit in history.
- `git integrate` - Integrate modifications from the remote repository.
- `git release-beta` - Start a new release branch using Git Flow.
- `git release-hotfix` - Start a new hotfix branch using Git Flow.
- `git release-prod` - Finish a release or hotfix branch using Git Flow.
- `gh-prod` - Trigger the `release-prod` GitHub Actions workflow (`gh workflow run release-prod.yml`).
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

## Git Fix Date and Git Fix Secrets

- `git fix date` reschedules commit dates and times in history (e.g. weekday commits moved outside working hours), keeping their order — see [`git-fix-date`](https://github.com/tomgrv/scripts/tree/main/git-fix-date).
- `git fix secrets` redacts a literal secret from files, commit messages and tag messages across history — see [`git-fix-secrets`](https://github.com/tomgrv/scripts/tree/main/git-fix-secrets).

Both rewrite history: use `-f` carefully, it allows overwriting pushed history.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
