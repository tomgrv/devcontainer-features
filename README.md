<!-- @format -->

# Dev Container Features

Ready-made [Dev Container](https://containers.dev) features for git workflow,
commit hooks, versioning, AI coding skills, Kubernetes and more. Pick the ones
you need; each is independent and documents its own options.

## Quick start

Add features to `.devcontainer/devcontainer.json`:

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:11": {},
    "ghcr.io/tomgrv/devcontainer-features/githooks:11": {}
}
```

Rebuild the container and they are ready. The id is always
`ghcr.io/tomgrv/devcontainer-features/<feature>:11`.

## Features

| Feature                                      | `<feature>`    | Description                                                               |
| -------------------------------------------- | -------------- | ------------------------------------------------------------------------- |
| [GitUtils](./src/gitutils/README.md)         | `gitutils`     | Git aliases and workflow automation                                       |
| [GitHooks](./src/githooks/README.md)         | `githooks`     | Commit hooks: commitlint, prettier, lint-staged                           |
| [GitVersion](./src/gitversion/README.md)     | `gitversion`   | Semantic versioning via GitVersion                                        |
| [Act](./src/act/README.md)                   | `act`          | Run GitHub Actions locally via nektos/act                                 |
| [Larasets](./src/larasets/README.md)         | `larasets`     | Laravel-specific development utilities                                    |
| [Common Utils](./src/common-utils/README.md) | `common-utils` | Shared utilities (`jq`, `dos2unix`, ...) used by other features           |
| [Gateway](./src/gateway/README.md)           | `gateway`      | SSL inspection certs for corporate networks; also installable on the host |
| [Minikube](./src/minikube/README.md)         | `minikube`     | Local Kubernetes cluster via Minikube                                     |
| [Scripting](./src/scripting/README.md)       | `scripting`    | Standard root `setup.sh` bootstrapping `zz-use` and the repo entrypoint   |
| [AI Coding](./src/ai-coding/README.md)       | `ai-coding`    | Agent-agnostic AI coding skills + Claude Code GitHub Action               |

Each feature has its own README with its options and commands.

## Install without a dev container

The same features install from a terminal on any machine (host, Codespaces,
running container). They set up the tool and copy the feature's files
(`.devcontainer/`, `.github/`, editor config...) into the current project.

```sh
npx tomgrv/devcontainer-features -- add gitutils   # one feature
npx tomgrv/devcontainer-features -- add -a         # all of them
npx tomgrv/devcontainer-features -- init           # root files only
npx tomgrv/devcontainer-features -h                # all commands
```

No Node.js? Use curl instead (everything after `-s --` is passed through):

```sh
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gitutils
```

Set `DEVCONTAINER_FEATURES_REF` to install from another branch, tag or commit.
Features are also published to npm as `@tomgrv/devcontainer-features-<feature>`.

## Let an agent set it up

An [MCP server](./.mcp/README.md) lets an AI agent list the features, read their
docs and get the exact setup command for another repository.

## Contributing

Open an issue or a pull request against `develop`. Commit and PR title rules:
[`CLAUDE.md`](./CLAUDE.md).

## License

[MIT](./LICENSE).
