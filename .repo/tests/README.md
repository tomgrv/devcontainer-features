<!-- @format -->

# Repo-wide tests

Bats suites here test a convention across the **whole repository**, not one
feature/workspace — e.g. guarding against a class of bug in how features
reference each other, or in how `stubs/` files are laid out. Modeled on
[`tomgrv/actions/self-repo-syntax`](https://github.com/tomgrv/actions/tree/develop/self-repo-syntax).

A workspace-specific test (exercising one feature's own script or config)
belongs in that feature's own `src/<feature>/tests/` instead — see the
[Feature Pattern](../../CLAUDE.md#feature-pattern) in the root `CLAUDE.md`.

## Running

```sh
bats .repo/tests/
```

CI runs this automatically via `.github/workflows/test-workspaces.yaml`'s
`repo-tests` job, silently skipped when this directory has no `*.bats` files
(as it does today — none exist yet).
