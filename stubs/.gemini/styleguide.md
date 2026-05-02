<!-- @format -->

# Repository Style Guide

## Reviewer Behaviour

**Always propose concrete code changes.** For every issue, smell, or improvement identified
during a review, Gemini must provide an actionable code suggestion using GitHub's
suggestion block syntax:

```suggestion
// corrected code here
```

Observations without an accompanying code suggestion are not sufficient.
When a fix is non-trivial or spans multiple files, provide the corrected snippet
for each affected location and explain the rationale inline.

## Commit Messages

All commit suggestions **must** follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification with [devmoji](https://github.com/folke/devmoji#default-devmoji-reference). This ensures a consistent commit history and enables automated changelog generation.

### Format

```
<type>[optional scope]: <devmoji icon> <description>

[optional body]

[optional footer(s)]
```

#### Scope

Scope should be sub-package or module name that can be deducted from the code changes and pointing to a sub package or module (eg: npm workspaces, composer local packages). If the change is not specific to a sub-package or module, the scope can be omitted.

#### Breaking Changes

A breaking change is any change that would require consumers to modify their code when updating to the new version. In such cases, the commit message must include a `!` after the type/scope and a `BREAKING CHANGE:` footer describing the change and its impact.

### Allowed Types

| Type       | When to use                              |
| ---------- | ---------------------------------------- |
| `feat`     | A new feature                            |
| `fix`      | A bug fix                                |
| `docs`     | Documentation-only changes               |
| `style`    | Formatting, whitespace (no logic change) |
| `refactor` | Code restructure without feature/fix     |
| `perf`     | Performance improvement                  |
| `test`     | Adding or updating tests                 |
| `chore`    | Build process, dependencies, tooling     |
| `ci`       | CI/CD configuration changes              |
| `revert`   | Reverts a previous commit                |

### Rules

- The **type** is mandatory and must be lowercase.
- The **description** must be in the imperative mood, lowercase, must **not** end with a period.
    - ✅ `fix(auth): handle expired token gracefully`
    - ❌ `Fixed the auth bug.`
- Breaking changes must append `!` after the type/scope and include a `BREAKING CHANGE:` footer.
    - Example: `feat!: drop support for Node 14`
- **Every** code suggestion that would result in a commit must include a Conventional Commit-compliant
  commit message proposal in the review comment.

## Code Style

- Prefer clarity over cleverness.
- Keep functions small and single-purpose.
- Document public APIs and non-obvious logic.
- Prefer early returns over deeply nested conditionals.
- Flag any code that could be simplified, extracted, or made more idiomatic — and always
  provide the simplified version as a suggestion block.
