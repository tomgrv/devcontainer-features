<!-- @format -->

# Git Hooks

This feature provides a set of hooks for working with Git repositories.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/githooks:10": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add githooks
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add githooks
```

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-githooks
```

## Functional Coverage

- pre-commit - Runs git-pre-commit to validate the code before committing and lint-staged to lint and format staged files.
- prepare-commit-msg - Runs commitizen to prepare commit messages.
- commit-msg - Runs commitlint to validate commit messages.
- post-merge - Handles changes in package.json and composer.json after a merge.
- post-checkout - Runs git update to update the current branch with the latest changes from the remote.
- pre-push - Runs validate-branch-name to validate the branch name before pushing.

## Installation Mechanism

Hooks are wired up via [Husky](https://typicode.github.io/husky/how-to.html) rather than a raw `core.hooksPath .git/hooks` symlink setup. Installing husky and installing the hook commands it calls are one step, `.husky/install.sh` (deployed from `stubs/`), so hooks work wherever the repo is used:

- `.husky/install.sh` - idempotent, never fails its caller:
    - bootstraps `zz-use` from [`tomgrv/scripts`](https://github.com/tomgrv/scripts) when missing (`ZZ_SCRIPTS_SETUP_URL` overrides the `setup.sh` URL);
    - installs the `git-hook-*` commands onto `PATH` via `zz-use`, and `@tomgrv/devcontainer-features-common-utils` globally when `json-normalize` (used by the lint-staged config) is missing;
    - runs `husky` (local, else `npx --yes husky`) unless `core.hooksPath` is already `.husky/_`;
    - when `CLAUDE_ENV_FILE` is set, persists the bin dirs on `PATH` for the rest of the Claude Code session;
    - `HUSKY=0` skips it entirely.
- It is called from every entry point:
    - **npm** - the `package.json` `"prepare": "sh .husky/install.sh || ..."` script, so a plain `npm install` on any machine installs working hooks. (An existing `prepare` script in a consumer `package.json` is kept as-is by the JSON merge; replace it by hand to opt in.)
    - **devcontainer** - `configure-husky.sh` (run by `feature-configure githooks` on `postCreate`).
    - **Claude Code** - a `SessionStart` hook merged into `.claude/settings.json` (`stubs/.claude/_githooks.settings.json`), since claude.ai/code web/cloud sessions clone the repo directly and run neither `npm install` nor `postCreate`.
- `configure-hooks.sh` generates one thin executable wrapper per hook under `.husky/` (`pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-checkout`, `post-merge`, `pre-push`). Each wrapper calls the corresponding `git-hook-<name>` command (no internal hyphens, e.g. `pre-commit` -> `git-hook-precommit`), passing all arguments through, and falls back to sourcing `.husky/install.sh` if `zz-use` isn't on `PATH`:

    ```sh
    #!/bin/sh
    command -v zz-use > /dev/null 2>&1 || . "$(dirname "$0")/install.sh"
    zz-use -x git-hook-precommit "$@"
    ```

- Husky's own init sets `core.hooksPath .husky/_` - this feature doesn't touch `git config` directly.
- With real hooks active, the `ai-coding` feature's `lint-staged-precommit.sh` Claude `PreToolUse` hook steps aside, so lint-staged doesn't run twice per commit.

## Configuration

All hooks utilities are installed globally and can be configured in the `package.json` file.

A default configuration is provided for each utility, but you can override it by modifying the `package.json` file.

### validate-branch-name

Unlike the other utilities, `validate-branch-name`'s `package.json` config is not static: `configure-validate-branch-name.sh` (run automatically by `feature-configure githooks`) generates it from the git-flow branch/prefix scheme set up by the `gitutils` feature (`gitflow.branch.master`, `gitflow.branch.develop`, `gitflow.prefix.feature`, `.bugfix`, `.release`, `.hotfix`, `.support`), plus a `main`/`develop`/`feature`/`bugfix`/`release`/`hotfix`/`support` fallback when git-flow isn't configured. AI coding agent branch prefixes (`copilot/`, `claude/`) are always allowed too, overridable via the `GITHOOKS_EXTRA_BRANCH_PREFIXES` environment variable (comma-separated). Re-run `feature-configure githooks` after changing the git-flow config to regenerate the pattern.

### lint-staged

The default `lint-staged` config formats JSON with `json-normalize` and everything else with prettier. Lockfiles are excluded from both globs (`!(*schema|package-lock).json` and a prettier glob that skips `package-lock`), because npm owns their formatting and the hook regenerates them whenever a `package.json` is staged. Earlier versions of this stub matched them, which rewrote the whole lockfile on any `package.json` commit.

`feature-configure githooks` merges this config into your `package.json`, and a JSON merge only adds keys. The two superseded globs are therefore removed by `KEY` lines in this feature's `.clean`, which needs a `feature-configure` from a [`tomgrv/scripts`](https://github.com/tomgrv/scripts) release that knows that directive; an older one prints `Unknown .clean directive` and skips the line. If that happens, delete these two keys from `lint-staged` in your `package.json` by hand:

- `!(*schema).json`
- `!(templates/**/*|.agents/**).{js,jsx,ts,tsx,md,html,css,vue,yaml,yml,json}`

## Hooks

The following hooks are provided:

- `pre-commit` - Executes `git-pre-commit` to validate the code before committing. It also runs `lint-staged` to lint and format staged files, ensuring code quality and consistency before changes are committed.
- `prepare-commit-msg` - Utilizes `commitizen` to help prepare standardized and conventional commit messages, making it easier to follow commit message guidelines.
- `commit-msg` - Runs `commitlint` to validate commit messages against defined rules, ensuring that all commit messages are consistent and follow the project's conventions.
- `post-merge` - Handles changes in `package.json` and `composer.json` after a merge, ensuring that dependencies are correctly updated and any necessary post-merge tasks are performed.
- `post-checkout` - Executes `git update` to synchronize the current branch with the latest changes from the remote repository, keeping the local branch up-to-date.
- `pre-push` - Runs `validate-branch-name` to ensure that the branch name adheres to the project's naming conventions before pushing changes to the remote repository.

## CI Workflows

Consumer repos get these deployed workflows under `.github/workflows/`. Each has a job timeout and a `concurrency` group: PR checks cancel superseded runs, scheduled jobs queue.

- `validate-pr-format.yml` — checks the PR title (commitlint + devmoji) and the PR source branch.
- `validate-pr-secret.yml` — scans the PR for secrets with gitleaks on open, reopen and every push; skipped when `GITLEAKS_LICENSE` is not set.
- `update-labels.yml` — weekly sync of `.github/labels.json` to the repository labels (needs only `issues: write`).
- `clean-branches.yml` — weekly deletion of branches whose pull request is closed.
- `configure-github.yml` — weekly restriction of `main` to the GitHub Actions bot.

## Customizations

The feature also includes the following VS Code customizations:

- Extensions:
    - `vivaxy.vscode-conventional-commits`
    - `softwareape.rebaser`
    - `tomblind.scm-buttons-vscode`

- Settings:
    - `conventionalCommits.gitmoji`: `false`

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
