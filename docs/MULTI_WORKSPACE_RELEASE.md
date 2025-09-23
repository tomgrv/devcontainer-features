<!-- @format -->

# Multi-Workspace Release Automation

This document describes the automated release process for the devcontainer-features repository, which supports multi-workspace releases with semantic versioning, conventional commits, and gitflow integration.

## Overview

The repository contains 7 independent workspaces (devcontainer features) that can be released individually or together:

- `act` - Nektos Act for local GitHub Actions
- `common-utils` - Shared utilities for other features
- `githooks` - Git hooks for development workflow
- `gitutils` - Git aliases and workflow automation
- `gitversion` - GitVersion tool for semantic versioning
- `larasets` - Laravel-specific development tools
- `pecl` - PHP Extensions installer

Each workspace has its own versioning managed in its `devcontainer-feature.json` file.

## Release Process

### Manual Trigger

The release process is triggered manually via GitHub Actions workflow dispatch:

1. Go to the **Actions** tab in the GitHub repository
2. Select **Multi-Workspace Release Automation** workflow
3. Click **Run workflow**
4. Configure options:
    - **Dry run mode**: Preview changes without creating actual release
    - **Base branch**: Branch to compare against (default: `main`)

### Automated Steps

1. **Change Detection**: Analyzes git diff to identify modified workspaces
2. **Commit Analysis**: Uses conventional commits to determine version bump type
3. **Release Branch**: Creates gitflow-compliant release branch
4. **Version Updates**: Updates only affected workspace versions
5. **Pull Request**: Automatically creates PR for release branch

## Conventional Commits

The system analyzes commit messages to determine appropriate version bumps:

### Commit Format

```
<type>(<workspace>): <description>

[optional body]

[optional footer with BREAKING CHANGE]
```

### Version Bump Rules

| Commit Type         | Example                                  | Version Bump              |
| ------------------- | ---------------------------------------- | ------------------------- |
| `fix(workspace):`   | `fix(gitutils): resolve alias conflict`  | **Patch** (1.0.0 → 1.0.1) |
| `feat(workspace):`  | `feat(githooks): add new pre-push hook`  | **Minor** (1.0.0 → 1.1.0) |
| `feat(workspace)!:` | `feat(gitutils)!: change alias behavior` | **Major** (1.0.0 → 2.0.0) |
| `BREAKING CHANGE`   | Any commit with breaking change footer   | **Major** (1.0.0 → 2.0.0) |

### Examples

```bash
# Patch release for gitutils
git commit -m "fix(gitutils): correct git flow command syntax"

# Minor release for githooks
git commit -m "feat(githooks): add commitlint configuration validation"

# Major release for common-utils
git commit -m "feat(common-utils)!: change logging utility interface

BREAKING CHANGE: log function signature changed from log(msg) to log(level, msg)"

# Multiple workspaces in one commit
git commit -m "feat(gitutils,githooks): integrate new workflow automation"
```

## Gitflow Integration

### Branch Naming Convention

Release branches follow gitflow naming:

- Pattern: `release/multi-workspace-X.Y.Z`
- Example: `release/multi-workspace-5.26.0`

The version number is determined by the highest version change across all affected workspaces.

### Branch Lifecycle

1. **Creation**: `git flow release start multi-workspace-X.Y.Z`
2. **Development**: Version updates committed to release branch
3. **Review**: Pull request created for code review
4. **Completion**: Manual merge to main branch (not automated)

## Workspace Version Management

### Individual Versioning

Each workspace maintains independent semantic versioning:

```json
{
  "id": "gitutils",
  "name": "Git Aliases",
  "version": "5.25.0",
  ...
}
```

### Selective Updates

Only workspaces with actual changes get version bumps:

- **Changed files**: Direct modifications in `src/workspace/`
- **Conventional commits**: Commits with workspace scope
- **No changes**: Version remains unchanged

### Version Calculation

The system uses semantic versioning rules:

```bash
# Current: 1.2.3
fix(workspace): description     # → 1.2.4 (patch)
feat(workspace): description    # → 1.3.0 (minor)
feat(workspace)!: description   # → 2.0.0 (major)
```

## Workflow Configuration

### Inputs

| Input         | Type    | Default | Description                         |
| ------------- | ------- | ------- | ----------------------------------- |
| `dry_run`     | boolean | `false` | Preview mode without actual changes |
| `base_branch` | string  | `main`  | Base branch for change comparison   |

### Outputs

The workflow provides detailed summaries:

- **Changed workspaces**: List of affected workspaces
- **Version changes**: Before/after versions for each workspace
- **Release branch**: Created branch name
- **Pull request**: Automatically created PR link

## Usage Examples

### Full Release Process

```bash
# 1. Make changes to workspaces
echo "new feature" >> src/gitutils/README.md
git add .
git commit -m "feat(gitutils): add new documentation section"

# 2. Trigger workflow via GitHub UI
# - Go to Actions → Multi-Workspace Release Automation → Run workflow
# - Choose dry_run: false, base_branch: main

# 3. Review created PR
# - Check version updates are correct
# - Verify conventional commit analysis
# - Merge when ready
```

### Dry Run Testing

Use dry run mode to preview changes:

```bash
# Trigger with dry_run: true
# - Shows what workspaces would be updated
# - Displays calculated version changes
# - No actual branches or PRs created
```

### Multi-Workspace Changes

For commits affecting multiple workspaces:

```bash
# Update multiple features
git commit -m "feat(gitutils,githooks): integrate new workflow

- Add release automation to gitutils
- Update hooks for new workflow in githooks"

# Result: Both gitutils and githooks get minor version bumps
```

## Troubleshooting

### Common Issues

1. **No Changes Detected**
    - Ensure commits follow conventional commit format
    - Check that files were actually modified in workspace directories
    - Verify workspace scope in commit messages

2. **Wrong Version Bump**
    - Review conventional commit message format
    - Check for BREAKING CHANGE in commit footer
    - Ensure workspace name matches directory name

3. **Release Branch Exists**
    - Complete or abandon existing release branches
    - Use different base branch if needed
    - Check git flow configuration

### Debugging

Enable debug output by checking workflow logs:

- **Change Detection**: Shows analyzed commits and file changes
- **Version Calculation**: Displays semver calculations
- **Branch Creation**: Shows git flow commands executed

## Integration with Existing Tools

### GitVersion Compatibility

The workflow integrates with existing GitVersion configuration while adding workspace-specific versioning.

### devcontainer Features

Each workspace remains a valid devcontainer feature with proper versioning in `devcontainer-feature.json`.

### Existing Scripts

Current git utilities like `_git-release-beta.sh` continue to work for manual releases.

## Best Practices

### Commit Guidelines

1. **Use conventional commits** for all workspace changes
2. **Include workspace scope** in commit messages
3. **Group related changes** in single commits when possible
4. **Use BREAKING CHANGE** footer for major version bumps

### Release Management

1. **Review dry runs** before actual releases
2. **Test release branches** in development environments
3. **Document breaking changes** in commit messages
4. **Coordinate multi-workspace** changes when possible

### Workflow Maintenance

1. **Monitor workflow execution** for errors
2. **Update conventional commit** patterns as needed
3. **Maintain workspace list** when adding/removing features
4. **Keep documentation** synchronized with changes
