---
description: 'Use when writing or reviewing git commit messages, changelogs, or version bumps. Covers Conventional Commits rules, scopes, and types.'
---

<!-- @format -->

## Commit Message Format

Commit message titles must follow [Conventional Commits](https://www.conventionalcommits.org/) rules.

**Pattern:** `<type>(<scope>): <summary>`

- **Type**: one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`
- **Scope**: lowercase, matches the affected module or component (e.g. `gitutils`, `githooks`, `api`)
- **Summary**: brief, imperative, no period at the end
- **No emoji** in the title — emojis are added automatically based on type

**Examples:**

```
feat(login): add OAuth2 support
fix(api): correct null pointer error in user endpoint
docs(readme): update installation instructions
refactor(auth): streamline token validation logic
chore(deps): bump version of express to 4.18.2
```

**Important:** Always follow the commitlint configuration in root `package.json` for the full list of allowed types and scopes.
