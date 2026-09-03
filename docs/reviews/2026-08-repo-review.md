<!-- @format -->

# Repo Review: Optimize, Simplify, Streamline

Date: 2026-08-12
Scope: whole repository — CI/workflows, `src/*` feature source, and the `.agents/` AI-tooling layer.
This is a findings-only report. No code changes are included in this pass; each item below
is written so a follow-up PR can act on it independently.

> **2026-09 update:** `pecl` (the subject of §2.5 and several other findings below) has been
> removed from this repository rather than brought into conformance — the findings that
> reference it are kept as-is for the historical record, but no longer describe anything
> present in `src/`. `CLAUDE.md`'s "minimal reference" feature pointer was moved to
> `src/scripting/`.

## Executive Summary

Six items stand out by impact-to-effort:

1. **Two pairs of duplicate CI workflows run simultaneously on every `main` push and every tag
   push** (`merge-monorepo.yml` / `manage-monorepo-merge.yml`, `split-monorepo.yml` /
   `manage-monorepo-split.yml`). This roughly doubles matrix-job CI minutes and risks opening
   duplicate PRs against child repos. Deleting the stale pair is a same-day fix.
2. **Dogfooding is broken**: this repo's own secret-scanning workflow
   (`gitleaks/gitleaks-action@v3`) is not what the `githooks` feature ships to consumers
   (`tomgrv/actions/check-secret@v2`). The repo isn't running what it publishes.
3. **8 of 9 non-`ai-coding` features have zero automated tests**, and `publish-features.yml`
   publishes to npm on every `main` push with no test gate at all — including `githooks`
   (controls commit enforcement) and `gitutils` (release automation).
4. **`ai-coding`'s own npm package ships nothing**: its `package.json` `files` field excludes
   `stubs/**/*`, so `npm install`-ing the feature deploys none of its skill content.
5. **`ai-coding` has grown into the largest feature in the repo** (372K, 55 files — bigger than
   `gitutils`) while the README still describes it in one line. ~71% of its 28 skills trace to
   two third-party plugin vendors, and 46% of them are never actually shipped to consumers.
6. **A copy-pasted `cd "$(git rev-parse --show-toplevel)")` idiom appears ~45 times** across 6
   features with inconsistent error handling — the strongest concrete candidate in the repo for
   extraction into a shared `common-utils` helper.

Everything below expands on these and adds lower-priority findings, organized by layer.

---

## 1. CI / Workflows (`.github/workflows/`)

### 1.1 Duplicate workflows double-running (highest priority)

`merge-monorepo.yml` and `manage-monorepo-merge.yml` are identical except one version pin
(`create-pr@v1` vs `create-pr@v2`). `split-monorepo.yml` and `manage-monorepo-split.yml` are
identical except a quoting difference in the `name:` field. All four trigger on
`workflow_dispatch`, and the split pair _also_ both trigger on `push: branches: [main]` and
`tags: '*'` — meaning **every push to `main` and every tag push runs the split logic twice**,
independently spinning up `list-packages` (checkout + setup-php + setup-node + list-packages)
and a full per-package matrix in each run.

These four workflows are installed from `src/gitutils/stubs/.github/workflows/` as part of this
repo dogfooding its own `gitutils` feature (per `CLAUDE.md`). The canonical names are
`manage-monorepo-merge.yml` / `manage-monorepo-split.yml`; `merge-monorepo.yml` /
`split-monorepo.yml` look like stale copies left over from before a rename that were never
cleaned out of the root `.github/workflows/`.

**Recommendation:** delete `merge-monorepo.yml` and `split-monorepo.yml`, keep the
`manage-monorepo-*` pair (confirm against the current `gitutils` stub before deleting). This
alone removes duplicate CI runs and the duplicate-PR risk on every release-adjacent push.

### 1.2 Dogfooding drift between root workflows and their stub source

- `validate-pr-secret.yml` (root) uses `gitleaks/gitleaks-action@v3` with no license secret and
  no `checks: write` permission. The stub this repo ships via the `githooks` feature
  (`src/githooks/stubs/.github/workflows/validate-pr-secret.yml`) uses a different action
  entirely: `tomgrv/actions/check-secret@v2`, with a `GITLEAKS_LICENSE` secret and
  `checks: write`. This isn't a version-pin drift — it's two different implementations. If the
  intent is "this repo runs its own features' output," that invariant currently doesn't hold.
- `update-labels.yml`: the stub uses `actions/checkout@v6` + `tomgrv/actions/update-labels@v2`;
  the installed root workflow uses `checkout@v7` + `update-labels@v1` — root is _ahead_ on
  checkout but _behind_ on the custom action.
- `claude.yml`, `validate-pr-format.yml`, `release-main.yml` differ from their stubs only by
  `actions/checkout` version (root is ahead, e.g. `v4`→`v7`), showing the stub templates
  generally aren't kept in sync with what's actually installed.

**Recommendation:** decide whether root workflows are meant to always match their stub source
exactly. If yes, resync and consider a CI check that diffs installed workflows against their
stub origin. If some intentional divergence is expected (e.g. root doesn't need a
`GITLEAKS_LICENSE`), document it inline in the workflow file so future drift is distinguishable
from accidental drift.

### 1.3 Test coverage gap

Root `test/` (introduced in #109, "reorganize tests to root test folder") uses a hand-rolled
POSIX-sh harness (`test/lib.sh`: `assert_eq`, `assert_status`, `report()`,
`setup_feature_utils()`). Only `test/common-utils/` is populated (5 files, 337 lines). The other
8 features — `act`, `ai-coding`, `gateway`, `githooks`, `gitutils`, `gitversion`, `larasets`,
`minikube`, `pecl` — have no test directory at all, including `githooks` (owns commit-message
and secret-scanning enforcement) and `gitutils` (owns release automation).

`check-common-utils.yml` is the only workflow that runs any test, and it's path-filtered to
`src/common-utils/**` — it isn't a required check gating the other 8 features.
`publish-features.yml` publishes every feature to npm and to the devcontainer index on every
push to `main`, with no test step anywhere in that workflow.

**Recommendation:** at minimum, add a test gate to `publish-features.yml` (even a smoke test —
"install the feature into a throwaway container and check the binaries exist" — beats nothing).
See §4 for a suggested harness alternative (`bats-core`) that would make writing per-feature
tests less bespoke than extending the current `test/lib.sh` pattern.

### 1.4 Commitlint enforcement is client-side only

Commitlint config lives in root `package.json` (extends `@commitlint/config-conventional` +
`@commitlint/config-workspace-scopes`, plus a custom `subject-case` rule) and is enforced via
the `commit-msg` git hook installed by the `githooks` feature
(`src/githooks/_commit-msg.sh:13-14`, runs `commitlint --edit "$1"`). No workflow in
`.github/workflows/` runs commitlint. `CLAUDE.md` states commits are "Validated by commitlint on
`review_requested`" — no workflow anywhere triggers on `review_requested`; the closest is
`validate-pr-format.yml` (`pull_request: types: [opened, ready_for_review]`), which checks PR
_title_ via `tomgrv/actions/check-pr-format@v2`, not commit body/type/scope. A local hook is
trivially bypassed with `git commit --no-verify` and is never re-checked server-side.

**Recommendation:** either add a real commitlint CI step (e.g. `commitlint --from <base>
--to HEAD` on `pull_request`), or correct `CLAUDE.md` to stop claiming CI-side validation that
doesn't exist.

### 1.5 Missing `synchronize` trigger on PR gate checks

`validate-pr-format.yml` and `validate-pr-secret.yml` both trigger only on
`[opened, ready_for_review]`, not `synchronize`. If a PR is opened, the title/secret check
passes, and then new commits are pushed, **neither check re-runs**. If either is configured as a
required status check in branch protection, GitHub shows it as still-passing (stale), which
would let a bad title or a newly-introduced secret merge in undetected.

**Recommendation:** add `synchronize` to both triggers.

### 1.6 Release process bootstraps itself from an unpinned self-reference

`release-main.yml` (manual `workflow_dispatch` only) checks out `develop`, then installs the
`gitutils` feature from this repo's own default-branch npm package
(`npm exec --yes --legacy-peer-deps --package github:tomgrv/devcontainer-features -- devcontainer-features -- add gitutils`)
purely to obtain the `git beta`/`git prod` aliases used to run the release. This is a
self-referential bootstrap with no version pin — a breakage in `install.sh`/`gitutils` on `main`
breaks the repo's ability to release itself, and release behavior can silently drift between
runs since nothing pins which commit of the repo is being installed.

**Recommendation:** pin the self-install to a tag/commit, or replace it with a direct
dependency on the already-checked-out `gitutils` source instead of round-tripping through npm.

### 1.7 Minor / lower-priority

- No `concurrency:` groups anywhere in the 13 workflows — rapid pushes to the same PR/branch can
  pile up overlapping runs instead of canceling superseded ones.
- No `actions/cache` or equivalent visible in any workflow (Node setup is delegated to the
  external `tomgrv/actions/setup-node@v2` action, whose internal caching can't be verified from
  this repo).
- Dependabot (`.github/dependabot.yml`) has one entry — `github-actions`, directory `/` — with no
  npm ecosystem entry, despite the repo being an npm workspace root with 10 workspace packages.
  npm dependency updates currently rely entirely on the separate scheduled
  `update-features.yml` job rather than Dependabot.
- In `split-monorepo.yml`/`manage-monorepo-split.yml`, the `split-packages` job's real work is
  gated by `if: !startsWith(github.ref, 'refs/tags/')`, but the preceding steps (full-history
  checkout, GitHub App token generation) run unconditionally per matrix package on every tag
  push, doing nothing useful — and currently doubled by the duplicate-workflow issue in §1.1.

---

## 2. Feature Source Layer (`src/*`)

All 10 features are npm-workspace members and, per `publish-features.yml`'s
`detect-npm-packages` job, all 10 are npm-publishable (none marked `private`), matching the
CLAUDE.md goal of making every feature npm-installable.

### 2.1 `cd "$(git rev-parse --show-toplevel)")` copy-pasted ~45 times

This idiom (jump to repo root before running feature logic) appears independently in `gitutils`
(24 occurrences), `larasets` (12), `gitversion` (3), `common-utils` (2), `act`, and `minikube`
(2), with inconsistent variants — `>/dev/null` vs `> /dev/null`, `|| exit 1`, `2>&1 || true`, or
assigning to a `repo_root` variable instead of `cd`ing directly (e.g.
`src/gitutils/configure-gitflow.sh:4`, `configure-knownhosts.sh:4`, `configure-gpg.sh:4`,
`src/githooks/configure-validate-branch-name.sh:4`).

**Recommendation:** extract a `zz_goto_root` (or similarly-named) helper into `common-utils`,
which already owns comparable helpers (`_zz_context.sh`, `_zz_args.sh`) but has no equivalent
for this extremely common operation. This is the single strongest, lowest-risk extraction
candidate in the repo.

### 2.2 `install-bin` inconsistently invoked relative to declared `bin` entries

`act`, `gitutils`, `gitversion`, `larasets`, and `minikube` call both `install-feature` and
`install-bin` in their `install.sh`. `gateway` and `githooks` declare `bin` entries in
`package.json` (`gateway-curl`; `commit-msg`, `pre-commit`, `pre-push`, `sync-versions`,
`update-version`, and others) but their `install.sh` is 4 lines and only calls `install-feature`
— confirmed by inspection, neither script calls `install-bin`. Via the devcontainer-feature
install path (`npx tomgrv/devcontainer-features -- add <feature>`), these commands never get
symlinked onto `PATH`; they only work today for consumers who happen to install via npm
directly, where npm's own bin-linking saves them.

**Recommendation:** add `install-bin` calls to `src/gateway/install.sh` and
`src/githooks/install.sh`, matching the other 5 stub-bearing features — likely a real bug, not
an intentional omission, since both declare `bin` entries they clearly expect to be wired up.

### 2.3 `ai-coding`'s npm package excludes its own payload

`src/ai-coding/package.json` sets `"files": ["install.sh"]`. Every other stub-bearing feature
(`act`, `gateway`, `githooks`, `gitutils`, `gitversion`, `larasets`, `minikube`) lists
`"stubs/**/*"` in `files`. Since `install.sh` calls `install-feature`, which copies
`$source/stubs` into the target repo, an `npm install`-based consumer of `ai-coding` would
receive `install.sh` and nothing else — the skill files that are the entire point of the
feature never ship. (`pecl` has the identical gap, but it's moot there since `pecl` never calls
`install-feature` in the first place — see §2.5.)

**Recommendation:** add `"stubs/**/*"` to `src/ai-coding/package.json`'s `files` array.

### 2.4 `gateway/_gateway-curl.sh` reimplements colors/logging

`src/gateway/_gateway-curl.sh` defines its own `RED`/`GREEN`/`YELLOW`/`NC` color codes and its
own `log()`/`warn()`/`error()` functions, duplicating `common-utils`'s `_zz_colors.sh` and
`_zz_log.sh`, even though `gateway` depends on `common-utils` and every other bin-style script
in the repo sources those shared helpers. This may be deliberate — the curl wrapper plausibly
needs to work before `common-utils`'s bins are symlinked onto `PATH` — but nothing documents
that reasoning today.

**Recommendation:** either source the shared helpers if load order permits, or add a one-line
comment explaining why this script can't (so it doesn't get "fixed" into a bug later).

### 2.5 `pecl` diverges from the pattern `CLAUDE.md` calls the minimal reference

`CLAUDE.md` names `src/pecl/` as "the minimal reference" for the standard feature pattern. In
practice, `pecl` is the one feature that deviates from it: `devcontainer-feature.json` has no
`postCreateCommand` (confirmed — every other feature ends with
`"postCreateCommand": {"config": "configure-feature <name>"}`, `pecl`'s does not), and
`install.sh` is a fully custom 17-line apt+pecl script that never calls
`install-feature`/`install-bin`. Its `stubs/.github/skills/feature-pecl/SKILL.md` is therefore
dead content — never deployed by `configure-feature` (no `postCreateCommand` to trigger it) and
never packaged into the npm tarball (`files: ["install.sh"]`, same gap as §2.3).

**Recommendation:** either bring `pecl` in line with the standard pattern (add
`postCreateCommand`, route through `install-feature`), or repoint `CLAUDE.md`'s reference
example at a feature that actually follows the pattern today — `act` or `minikube` are both
small and compliant.

### 2.6 No shellcheck gate; inconsistent quoting and shebang/`set -e` conventions

`common-utils`'s `devcontainer-feature.json` installs `shellcheck` as a default consumer util,
but no workflow in this repo runs shellcheck against the repo's own scripts. Concretely:

- `common-utils` core scripts (`_install-feature.sh`, `_configure-feature.sh`) leave path
  variables (`$source`, `$target`, `$dest`, `$file`) largely unquoted, which is fragile for
  values that could contain spaces; `gitutils` scripts are consistently double-quoted.
- 107 scripts use `#!/bin/sh`; 5 use `#!/bin/bash` (`gitutils/_git-fix-mode.sh`,
  `gateway/_gateway-curl.sh`, `githooks/_update-version.sh`, `common-utils/_validate-json.sh`,
  `common-utils/_normalize-json.sh`) and 1 uses `#!/usr/bin/env bash`
  (`common-utils/_zz_input.sh`) — presumably because they use bash-only features, but no
  documented convention states when `bash` is required over `sh`.
- `set -e` appears in only ~28 of 138 scripts, with no visible rule for which scripts opt in
  (most of `larasets`' Sail-aware wrappers do; most of `gitutils`' `git-fix-*` scripts rely on
  manual `&&`/`||` chains instead).

**Recommendation:** add a `shellcheck` (and optionally `shfmt`) CI step over `src/**/*.sh`. This
would catch the quoting issue mechanically and, over time, forces the `sh`/`bash` and `set -e`
choices to be consistent per shellcheck's own directive comments.

---

## 3. AI-Tooling Layer (`.agents/`)

### 3.1 The symlink mechanism is sound; the problem is content scope

`.agents/skills/<name>/` is the canonical source, symlinked into `.github/skills/` (Copilot) and
`.claude/skills/` (Claude Code, dogfood-only). All symlinks in both directories resolve
correctly — no broken links found. The mechanism itself is well-engineered and reusable.

What's disproportionate is what has grown inside it. Per the root `README.md`, `ai-coding` is
described in one line: "Agent-agnostic AI coding skills (`.github/skills/`) plus the Claude Code
GitHub Action for `@claude` mentions." Measured against that:

- **By file count, `ai-coding` is the largest feature in the repo** (55 tracked files, vs. 50
  for `gitutils`, 41 for `larasets`; every other feature is under 20).
- **By disk size, it's comparable to the repo's flagship feature** (372K vs. `gitutils`'s 268K).
- Of its 28 skills, **~71% (20) trace to two third-party plugin vendors** — `caveman` and
  `ponytail` — not to devcontainers-specific tooling. Six of those (`caveman-discover`,
  `caveman-evidence-review`, `caveman-learn`, `caveman-manage`, `caveman-optimize`,
  `caveman-setup` — 783 lines) are entirely about operating a paid third-party SaaS product
  ("Caveman Cloud"): onboarding, billing/experiment lifecycle, cost dashboards. None of these
  are distributed to consumers, and none relate to devcontainers.
- **13 of 28 skills (46%) are dogfood-only**: symlinked into this repo's own `.claude/skills/`
  but never copied into `src/ai-coding/stubs/.agents/skills/` and never added to
  `ai-coding.json`'s `skills` array (currently `[]`). These are `caveman-discover`,
  `caveman-evidence-review`, `caveman-explore`, `caveman-learn`, `caveman-manage`,
  `caveman-optimize`, `caveman-setup`, `investigate-first`, `lean-build`, `migration`,
  `safe-refactor`, `surgical-patch`, `verify-and-stop`. All are git-tracked, committed content —
  they never went through the "adding a new distributable skill" steps `.agents/README.md`
  itself documents (steps 2–4: copy into `src/ai-coding/stubs/`, symlink into
  `.github/skills/`, register in `ai-coding.json`). This is ongoing maintenance surface that
  produces zero value for the feature's actual consumers.

### 3.2 Internal redundancy within the vendored skill clusters

- The "ponytail anti-over-engineering" cluster (`ponytail`, `-audit`, `-debt`, `-gain`, `-help`,
  `-review` — 6 skills, 391 lines) has real overlap: `ponytail-audit` and `ponytail-review` are
  the same "find bloat" logic at two different scopes (whole-repo vs. PR diff); `ponytail-gain`
  is a one-shot vanity-metric display, not a working tool.
- `cavecrew` and `caveman-explore` both implement "read-only repo exploration with compressed
  output" — overlapping with each other and with the built-in `Explore` agent type. Neither is
  distributed.
- The generic workflow-discipline sextet (`investigate-first`, `lean-build`, `migration`,
  `safe-refactor`, `surgical-patch`, `verify-and-stop` — 100 lines total) reads like a stock
  skill pack rather than repo-authored guidance, and `lean-build` in particular duplicates the
  intent of `ponytail` (YAGNI discipline) without being wired into distribution.

### 3.3 `caveman`/`ponytail` are declared twice, via two independent mechanisms

Both are present as vendored skill-file copies under `.agents/skills/` _and_ as live Claude Code
plugins pulled at runtime from third-party GitHub repos
(`https://github.com/JuliusBrussee/caveman.git`,
`https://github.com/DietrichGebert/ponytail.git`) via `ai-coding.json`'s `plugins` array and
`.claude/settings.json`'s `enabledPlugins`. This is two independent delivery/update paths for
what is likely overlapping content from the same vendors, with no visible reconciliation between
them — a change to one path won't propagate to the other.

### 3.4 Instruction docs are stale relative to the AI-tooling layer's growth

`.github/instructions/repo.instructions.md` (74 lines, the Copilot-facing architecture doc)
lists only 8 features in its table and omits both `ai-coding` and `minikube`, which exist in
`src/` and are listed in the root README's feature table. Recent commit history shows `ai-coding`
changing rapidly (skill registry moves, plugin management changes) without the instructions
layer being updated to match.

### 3.5 Recommendation

Pick one of two positions on purpose, rather than continuing to grow by default:

- **Scope back down**: keep `ai-coding` to what the README actually describes — agent-agnostic
  skills plus the `@claude` GitHub Action. Cut the Caveman-Cloud SaaS-onboarding cluster (it's
  vendor product tooling, not a devcontainer feature), cut or finish-wiring the 13 dogfood-only
  skills (either ship them to consumers or delete them — don't leave them half-plumbed), and
  collapse the internally-redundant ponytail/explore pairs.
- **Own it explicitly**: if the intent is for this repo to also be a distribution point for a
  broader "AI agent tooling" product, update the README to say so honestly (it currently
  undersells `ai-coding`'s actual size by an order of magnitude), and accept the larger
  maintenance surface as a deliberate tradeoff rather than organic growth.

Either is defensible; the current state — quietly becoming the largest feature in the repo while
the docs still describe it as a one-liner — is the actual finding.

---

## 4. Cross-Cutting Doc/Reality Drift

Collected in one place since they share a root cause: nothing currently checks documentation
claims against the tree, so they drift independently as the codebase changes.

| Claim                                                                               | Location                                    | Reality                                                                                                            |
| ----------------------------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Commits "Validated by commitlint on `review_requested`"                             | `CLAUDE.md`                                 | No workflow triggers on `review_requested`; the closest workflow checks PR title only, not commitlint rules (§1.4) |
| `src/pecl/` is "the minimal reference" feature pattern                              | `CLAUDE.md`                                 | `pecl` is the one feature that doesn't follow the pattern (§2.5)                                                   |
| Feature table lists 8 features                                                      | `.github/instructions/repo.instructions.md` | 10 features exist in `src/`; `ai-coding` and `minikube` are missing (§3.4)                                         |
| `ai-coding` = "Agent-agnostic AI coding skills… plus the Claude Code GitHub Action" | root `README.md`                            | Now the largest feature in the repo by file count and disk size (§3.1)                                             |

---

## 5. Suggested Functional Alternatives

Per the ask for alternatives where eligible, not just cuts:

1. **Test harness**: replace or supplement the hand-rolled `sh` harness in `test/lib.sh` with
   `bats-core` for the 8 currently-untested features. It's closer to the devcontainer-feature
   ecosystem's own convention (the `devcontainer-cli`'s native `features test` scaffolding also
   expects a bats-style layout), gets TAP-format matrix reporting for free, and would lower the
   barrier to actually writing the missing tests from §1.3.
2. **Duplicate workflow logic**: instead of four workflows each containing a byte-for-byte
   identical `list-packages` job, extract it into a single reusable `workflow_call` workflow
   invoked by both `manage-monorepo-merge.yml` and `manage-monorepo-split.yml` (after §1.1's
   dedup). Removes ~20 lines of duplicated YAML per file and means future changes to that job
   only need to happen once.
3. **Quoting/shebang consistency**: add `shellcheck` as a CI step (it's already installed as a
   default `common-utils` consumer util, so the tooling is already "in the family") rather than
   relying on manual review to catch unquoted variables or shebang mismatches — see §2.6.

---

## Appendix: Verification Notes

Key claims in this report were spot-checked directly against the tree at time of writing
(2026-08-12), including: the `merge-monorepo.yml`/`manage-monorepo-merge.yml` and
`split-monorepo.yml`/`manage-monorepo-split.yml` diffs (§1.1), the `gitleaks-action@v3` vs.
`check-secret@v2` divergence (§1.2), `src/ai-coding/package.json`'s `files` field (§2.3),
absence of `install-bin` in `src/gateway/install.sh` and `src/githooks/install.sh` (§2.2), and
absence of `postCreateCommand` in `src/pecl/devcontainer-feature.json` (§2.5). Line-count and
occurrence-count figures elsewhere in this report come from repo-wide search performed during
this review and were not re-counted line-by-line for every citation — treat exact counts as
approximate, the underlying findings as verified.
