<!-- @format -->

# Multi-Workspace Release Quick Reference

## 🚀 How to Trigger a Release

1. **Go to GitHub Actions**
    - Navigate to: `https://github.com/tomgrv/devcontainer-features/actions`
    - Select: **"Multi-Workspace Release Automation"**

2. **Run Workflow**
    - Click: **"Run workflow"**
    - Choose branch: `main` (default)
    - Options:
        - ☑️ **Dry run**: Preview changes without creating release
        - ⚙️ **Base branch**: Compare against `main`

3. **Review Results**
    - Check workflow summary for changed workspaces
    - Review automatically created pull request
    - Merge PR when ready

## 📝 Conventional Commit Examples

```bash
# Minor version bump (new feature)
git commit -m "feat(gitutils): add new git alias for branch cleanup"

# Patch version bump (bug fix)
git commit -m "fix(githooks): resolve pre-commit hook compatibility issue"

# Major version bump (breaking change)
git commit -m "feat(common-utils)!: change logging interface

BREAKING CHANGE: log function now requires level parameter"

# Multiple workspaces
git commit -m "feat(gitutils,githooks): integrate release automation"
```

## 🔄 Version Bump Rules

| Commit Pattern      | Example                 | Version Change      |
| ------------------- | ----------------------- | ------------------- |
| `fix(workspace):`   | `fix(gitutils): typo`   | `5.25.0` → `5.25.1` |
| `feat(workspace):`  | `feat(gitutils): alias` | `5.25.0` → `5.26.0` |
| `feat(workspace)!:` | `feat(gitutils)!: api`  | `5.25.0` → `6.0.0`  |

## 📦 Current Workspace Versions

| Workspace      | Current Version | Description                         |
| -------------- | --------------- | ----------------------------------- |
| `act`          | 1.6.1           | Nektos Act for local GitHub Actions |
| `common-utils` | 3.17.0          | Shared utilities                    |
| `githooks`     | 5.11.3          | Git hooks for development           |
| `gitutils`     | 5.25.0          | Git aliases and automation          |
| `gitversion`   | 5.2.1           | GitVersion tool                     |
| `larasets`     | 5.10.2          | Laravel development tools           |
| `pecl`         | 1.0.7           | PHP Extensions installer            |

## ⚡ Quick Test Workflow

```bash
# 1. Make a change
echo "test feature" >> src/gitutils/README.md

# 2. Commit with conventional format
git add .
git commit -m "feat(gitutils): add test documentation"

# 3. Push to trigger release detection
git push

# 4. Run workflow via GitHub UI with dry_run: true
# 5. Review what would be released
# 6. Run again with dry_run: false to create actual release
```

## 🔧 Troubleshooting

- **No changes detected**: Check conventional commit format
- **Wrong version bump**: Verify workspace name in commit scope
- **Workflow fails**: Check git-flow configuration and permissions
