<!-- @format -->

# Common Utils

This feature provides common utilities for the devcontainer features.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/common-utils:11": {
        "utils": "jq dos2unix"
    }
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add common-utils
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add common-utils
```

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-common-utils
```

## Options

| Options Id | Description               | Type   | Default Value             |
| ---------- | ------------------------- | ------ | ------------------------- |
| utils      | The utilities to install. | string | jq yq dos2unix shellcheck |

## Utilities

The following utilities are included by default:

- `jq`
- `dos2unix`

You can specify additional utilities to install by modifying the `utils` option in the `devcontainer.json` file.

## Customizations

The feature also includes the following VS Code customizations:

- Extensions:
    - `actboy168.tasks`
    - `gruntfuggly.triggertaskonsave`
    - `natizyskunk.sftp`
    - `formulahendry.auto-rename-tag`
    - `formulahendry.auto-close-tag`
    - `gruntfuggly.todo-tree`
    - `foxundermoon.shell-format`
    - `richie5um2.vscode-sort-json`

- Settings:
    - `editor.formatOnSave`: `true`
    - `editor.formatOnPaste`: `true`
    - `todo-tree.general.tags`: `["BUG", "HACK", "FIXME", "TODO", "XXX", "[ ]", "[x]", "NOTE"]`
    - `editor.indentSize`: `"tabSize"`
    - `editor.detectIndentation`: `true`
    - `editor.tabSize`: `4`

## Functional Coverage

- Installs specified common utilities such as jq and dos2unix.
- Installs [mikefarah/yq](https://github.com/mikefarah/yq) v4 (pinned
  release binary, via `zz-use yq`), which `yaml-merge` requires; a distro
  python `yq` already on `PATH` is rejected by `yaml-merge`.
- Supports specifying additional utilities to install.

## Devcontainer postStart

`stubs/.devcontainer/devcontainer.json` is merged into the consumer's `.devcontainer/devcontainer.json` and adds a `postStartCommand.npm` entry: `npm install` when a `package.json` exists and `npm` is on `PATH`.

## PR Checks (CI)

Consumer repos get these deployed workflows under `.github/workflows/`:

- `validate-pr-lock.yml` — validates `package.json`/`package-lock.json` and
  `composer.json`/`composer.lock` coherence via
  [`tomgrv/actions/check-lock`](https://github.com/tomgrv/actions/blob/main/check-lock/README.md),
  reporting drift inline via reviewdog. `check-lock` detects whichever
  manifests are present, so this one workflow covers both npm and Composer
  repos without needing a feature-specific variant. `common-utils` is a
  transitive dependency of almost every other feature in this repo
  (`gitutils`, `githooks`, `larasets`, …), so this check ships for nearly
  every consumer without them needing to add it explicitly.
- By default it checks the repo root only (`paths: '.'`). If your manifests
  live in subdirectories, edit the deployed workflow and pass a
  comma-separated `paths` list (e.g. `.,packages/foo`) to the `check-lock`
  step.
- `test-workspaces.yaml` — runs each npm/Composer workspace's own test suite
  with workspace granularity. It discovers workspaces via
  [`tomgrv/actions/list-packages`](https://github.com/tomgrv/actions/blob/main/list-packages/README.md)
  and, for every workspace, runs
  [`tomgrv/actions/run-workspace-tests`](https://github.com/tomgrv/actions/blob/main/run-workspace-tests/README.md)
  (backed by [`tomgrv/scripts/ws-test`](https://github.com/tomgrv/scripts/tree/main/ws-test)).
  A **draft** pull request only runs the workspaces its changes impact: the ones
  owning a changed file plus, transitively, the workspaces depending on them
  (`dependencies`/`peerDependencies`/`devDependencies`/`optionalDependencies`),
  computed by [`ws-impacted`](https://github.com/tomgrv/scripts/tree/main/ws-impacted) and passed to
  `list-packages` as its `filter`. Markdown impacts nobody; a changed file owned by
  no workspace (root manifest, shared test helpers, workflows) impacts everybody.
  Marking the pull request ready for review, pushing to a non-draft pull request,
  and pushes to `main`/`develop` run every workspace (branches without a pull
  request are no longer tested: open a draft one). Repo-wide `tests/` also wait
  for ready. The `Tests green` job fails if any test job failed or was cancelled:
  mark it as a required status check in branch protection to block merging.
  For each root `*.json` file found directly under a workspace (typically
  `package.json`), that command reads its `.scripts.test` entry as the
  workspace's generic test entrypoint:
    - no root `*.json` file in the workspace → silently skipped;
    - a `*.json` file present but no `.scripts.test` entry → warns, doesn't
      fail the workspace;
    - `.scripts.test` present → run it; a non-zero exit, or a zero exit with
      no output at all (a silently-empty test run), both fail the workspace.
      Add a `"scripts": {"test": "..."}` entry to a workspace's `package.json`
      (e.g. `"test": "bats tests/"`) to opt it into this workflow.
      The same workflow also runs a `repo-tests` job for repo-wide suites (tests
      that guard a convention across the whole repo rather than one workspace —
      see `tests/README.md`), silently skipped when `tests/` has no
      `*.bats` files.
      It runs on every push and pull request except markdown-only changes, and
      a newer run on the same ref cancels the one still in progress.
- `update-features.yml` — deployed with the repository's root `stubs/` by
  `npx tomgrv/devcontainer-features -- init`, not by this feature. Weekly (and
  on demand) it runs `npm exec -- tomgrv/devcontainer-features update -a` and
  opens a pull request when the installed features changed. Runs are queued,
  never overlapped.

## Install internals

- `feature-install` installs links for a feature's `bin/` scripts in a writable bin directory.
- It resolves the writable bin directory with this fallback order:
    1. `INSTALL_BIN_DIR` (or `/usr/local/bin` by default)
    2. `~/.local/bin`
    3. First writable directory found in `$PATH` (excluding `node_modules/.bin`)
    4. `<feature-target>/bin`

## Additional utilities

Installed from [`tomgrv/scripts`](https://github.com/tomgrv/scripts); each has its own README with usage and options.

| Utility                                                                            | Purpose                                                         |
| ---------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| [`zz-colors`](https://github.com/tomgrv/scripts/tree/main/zz-colors)               | color codes to source in your scripts                           |
| [`zz-log`](https://github.com/tomgrv/scripts/tree/main/zz-log)                     | log messages with color                                         |
| [`zz-args`](https://github.com/tomgrv/scripts/tree/main/zz-args)                   | parse command line arguments and print help in one go           |
| [`distribute-utils`](https://github.com/tomgrv/scripts/tree/main/distribute-utils) | copy the `zz-*` utilities into a project folder (was `zz-dist`) |
| [`zz-persist`](https://github.com/tomgrv/scripts/tree/main/zz-persist)             | upsert a `KEY=VALUE` into an env file and/or `/etc/profile.d`   |
| [`json-validate`](https://github.com/tomgrv/scripts/tree/main/json-validate)       | validate JSON against a local, inferred or remote schema        |
| [`json-normalize`](https://github.com/tomgrv/scripts/tree/main/json-normalize)     | order JSON keys by schema, then alphabetically                  |

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## GitLab CI

Each workflow above has a GitLab counterpart, deployed as a fragment merged into the repository's `.gitlab-ci.yml` (`stubs/_<workflow>...gitlab-ci.yml`). `tomgrv/actions` steps run through `zz-use -x tomgrv/actions/<name>`, with the action inputs set as environment variables.

- `.zz-use`: shared base image and `zz-use` bootstrap, extended by the jobs of every feature.
- `test-workspaces` / `repo-tests`: the workspace matrix is a loop; drafts are detected from the merge request title.
- `validate-pr-lock`: `check-lock`, reporting through reviewdog (`REVIEWDOG_GITLAB_API_TOKEN` variable required).
