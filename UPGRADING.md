<!-- @format -->

# Upgrading

How to ship, and consume, a **breaking change** in the scripts these features
install, without breaking CI, releases or consumer repos. Written from the
v9.0.0 release (`tomgrv/scripts` v1: `zz_*` → `zz-*`,
`<verb>-json|yaml` → `json-<verb>|yaml-<verb>`). Rename tables and the
renaming-repo checklist:
[`tomgrv/scripts/UPGRADING.md`](https://github.com/tomgrv/scripts/blob/main/UPGRADING.md).

## Version map

| Repo                           | Before | After  |
| ------------------------------ | ------ | ------ |
| `tomgrv/scripts`               | v0.34  | v1.0.0 |
| `tomgrv/actions`               | v2.46  | v3.0.0 |
| `tomgrv/devcontainer-features` | v8.29  | v9.0.0 |

A breaking change promotes the **major**: floating `@v8`-style tags and
`@v2` / `scripts-ref: v0` never follow a rename.

## Order of operations

1. `tomgrv/scripts` merged **and released** (its `main` has the new names;
   `src/common-utils/install.sh` downloads `setup.sh` from there, so
   `common-utils` tests fail until then).
2. `tomgrv/actions` merged and released (new major tag). Until it exists, CI
   here runs the old published `@v2` and fails at `zz_use: not found`.
3. **This repo** — pin `tomgrv/actions@<new major>` and
   `scripts-ref: <new scripts major>`, merge when green, dry-run then real
   `release-prod`.
4. Consumers re-run `configure-feature` (see below).

## Checklist in this repo

1. Rewrite names in `install.sh`, `install-*.sh`, `configure-*.sh`, stubs,
   `.clean` / `KEY` examples, READMEs, skills (edit the canonical
   `.agents/…` / `src/ai-coding/stubs/…`, not the symlinks) and bats tests.
2. `src/common-utils/install.sh`: `zz-use json "json-*" yaml "yaml-*" …`, so the
   dispatchers and every sibling are installed; shims are renamed
   (`zz-context zz-dist zz-edit zz-json`) and the tests assert the new names.
3. **Pin refs in deployed stubs too** (`src/*/stubs/.github/workflows/*`): they
   are copied into consumer repos, so a stale `@v2` there breaks every consumer.
4. Bats stubs that define a script as a shell **function** (`zz-log() {…}`) must
   become executables — `sh` cannot define hyphenated functions.
5. Test with a fresh cache: `ZZ_CACHE_DIR=$(mktemp -d) bats --recursive src/*/tests tests`.
   A stale `~/.cache/zz_scripts` makes `common-utils` look broken.
6. Merge `develop` again before finishing: features added meanwhile (e.g. the
   `gitutils` orphan-branch workflow) may still carry old names.
7. PR title: `<type>(devcontainer-features-<workspace>)!: <emoji> …`, ≤ 100
   chars. Squash-merge with `!` in the title and a `BREAKING CHANGE:` footer.

## Pitfalls we hit

- Quoted names (`"$TEST_BIN/zz_dist"`) are missed by naive rewrites — grep after.
- `sed -i` through a symlink replaces it with a regular file; rewrite regular
  files only and leave `package-lock.json` / `CHANGELOG.md` alone.
- Re-running a failed check reuses the old event payload; push or mark the PR
  ready for review instead. Ready-for-review also starts extra checks.
- `release-promote` pinned to an old tag still bootstraps `scripts` `main`; use
  the new major of `tomgrv/actions`.

## Upgrading a consumer repo

```sh
grep -rIl -E 'zz_(args|ask|bindir|call|colors|dispatch|input|install|log|menu|npx|persist|prompt|update|use)\b|(normalize|merge|validate|load)-json|merge-yaml' . \
  --exclude-dir=node_modules --exclude-dir=.git
grep -rn -E 'tomgrv/actions[^ ]*@v2|scripts-ref: v0' .github
```

Rename per the scripts table, move `@v2` → `@v3` and `scripts-ref: v0` → `v1`,
then re-run `configure-feature <feature>` (or rebuild the devcontainer) so the
updated stubs replace the old ones. `.clean` `KEY` directives that named
`merge-json` / `merge-yaml` behaviour now refer to `json-merge` / `yaml-merge`.

## Rollback

Pin the previous majors together (`tomgrv/actions@v2`, `scripts-ref: v0`,
feature `v8`). Mixing new scripts with old actions fails at `zz_use: not found`.
