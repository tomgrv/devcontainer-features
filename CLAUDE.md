<!-- @format -->

# devcontainer-features

Monorepo of reusable VS Code devcontainer features. Each feature lives under `src/<feature>/` with a `devcontainer-feature.json`, `install.sh`, a `README.md`, and optional `stubs/` (files deployed to consumer repos, merged into an existing file at the same path when one exists), `config/` (data files a script reads at runtime, e.g. JSON Schemas), `bin/` (scripts installed onto `PATH`), and `tests/` (bats test suites).

## All AI Tooling Lives in `.agents/` — Use It

Every tool-specific path is a symlink into `.agents/` (the single source of truth). See `.agents/README.md` for the full layout.

- **Skills** (`/.agents/skills/`, symlinked into `/.github/skills/` for Copilot and `/.claude/skills/` for Claude Code): `caveman*`, `cavecrew`, `caveman-stats`, `feature-ai-coding`, `pm/*`. Invoke them proactively via the Skill tool — don't wait until stuck.
- **Instructions** (`/.github/instructions/*.instructions.md` — Copilot's `applyTo`-glob convention; Claude doesn't auto-load these but they document repo conventions): `general`, `repo`, `commit`.

## Dev Workflow

- **Feature install** (local): `npx tomgrv/devcontainer-features -- add <feature>` → calls `zz_feature -i` → copies `src/<feature>/stubs/` via `cp -a` (symlinks preserved) into target.
- **Feature configure** (devcontainer): `zz_feature -c <feature>` → deploys stubs files + symlinks via `src/common-utils/bin/zz_feature.sh`.
- **This repo dogfoods its own features** — root `.github/workflows/`, `.github/skills/`, `.claude/skills/` are the installed output of the ai-coding feature. Edit canonical content under `.agents/skills/` or `src/ai-coding/stubs/`, not the symlinks.
- **Prettier**: run `npm install` then `npx prettier --write` on new/edited `.md`/`.yml`/`.json` files before committing.
- **Commits**: Conventional Commits + devmoji emoji required — e.g. `feat(scope): ✨ description`. Validated by commitlint on `review_requested`.
- **PR base**: always `develop`, not `main`.
- **CI workflow naming**: any workflow that runs code tests (bats or otherwise) is named `test-<scope>.yaml` under `.github/workflows/` (e.g. `test-common-utils.yaml`). Non-test workflows (`validate-*`, `check-*` for non-test checks, `manage-*`, `publish-*`, `release-*`, `update-*`) keep their existing prefixes.

## Feature Pattern

Each feature follows this structure (use `src/pecl/` as the minimal reference — just the standard entrypoints plus `stubs/`; `src/githooks/` or `src/larasets/` for a fuller example with all four optional subdirectories):

```
src/<feature>/
  devcontainer-feature.json   # id, version, dependsOn, postCreateCommand
  install.sh                  # runs: zz_feature -i $0
  package.json                # npm workspace registration
  README.md
  configure-*.sh               # optional lifecycle hooks, invoked by name (not on PATH)
  install-*.sh                 # optional extra install-time scripts
  stubs/                       # files deployed as-is to consumer repos; merged into an
                                # existing file at the same path (JSON via merge-json,
                                # otherwise git merge-file) when one already exists.
                                # A basename starting with "_" marks a qualifier segment
                                # (up to the first ".") to strip, so several fragments
                                # (_foo.package.json, _bar.package.json) can all resolve
                                # to and accumulate into the same target (package.json).
    .agents/skills/<name>/    # canonical real files
    .github/skills/<name>     # symlink → ../../.agents/skills/<name>
    .claude/skills/<name>     # symlink → ../../.agents/skills/<name>
  config/                      # optional: data files a script reads at runtime
                                # (JSON Schemas, alias/config maps, dependency manifests)
                                # — never deployed to consumers, never merged
  bin/                         # optional: scripts installed onto PATH by zz_feature -i
                                # (no leading underscore — directory location alone marks
                                # a file as a PATH script, unlike stubs/'s qualifier convention)
  tests/                       # optional: *.bats + helpers.bash, run via `bats src/<feature>/tests/`
```

## Minimal Changes Discipline

Change only what the task requires. Don't touch `package-lock.json`, `src/githooks/bin/pre-commit.sh` mode, or unrelated features unless the task explicitly calls for it.

## Claude Feedback Policy

**Never implement Copilot feedback or PR comments automatically.** Claude acts only on explicit requests—if you want me to address Copilot/GitHub feedback, mention `@claude` in a comment or message. This prevents well-intentioned but incorrect automated suggestions from landing in the codebase.

## PR Branch Rule

**Default base branch is `develop`, never `main`.** Only open PRs against `main` if:

- Explicitly asked ("create a PR against main")
- Marked as a hotfix (in commit message or request: `hotfix/...`, `@hotfix`)

If no branch is specified in a request, start from `develop`.

## PR Title Rule

**PR titles must follow Conventional Commits format with scope matching the affected workspace/feature.** Format: `<type>(devcontainer-features-<workspace>): <emoji> <description>`.

Valid scopes: `devcontainer-features-act`, `devcontainer-features-ai-coding`, `devcontainer-features-common-utils`, `devcontainer-features-gateway`, `devcontainer-features-githooks`, `devcontainer-features-gitutils`, `devcontainer-features-gitversion`, `devcontainer-features-larasets`, `devcontainer-features-minikube`, `devcontainer-features-pecl`, `devcontainer-features-scripting`.

Example: `fix(devcontainer-features-githooks): 🔧 Add conditional skip when GITLEAKS_LICENSE not set`.

Validated by `tomgrv/actions/check-pr-format@v2` on PR open/sync. Scope must use full `devcontainer-features-<workspace>` format; multi-workspace changes use the primary feature modified.
