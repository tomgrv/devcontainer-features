# Multi-workspace Release Automation

This repository includes an automated release workflow that handles version management for multiple workspaces (devcontainer features) according to semantic versioning and conventional commit standards.

## Overview

The multi-workspace release automation provides:

- **Workspace Change Detection**: Automatically detects which workspaces have been modified since the last release
- **Conventional Commit Analysis**: Analyzes commit messages to determine the appropriate semantic version bump (major/minor/patch)
- **Gitflow Integration**: Creates release branches following gitflow conventions before updating versions
- **Individual Version Management**: Updates only the workspaces that have been modified
- **Automated Pull Requests**: Creates PR to merge release branch into main

## Workflow Features

### ✅ Semantic Versioning (SemVer)
- **Major**: Breaking changes (BREAKING CHANGE in commit message or `!` suffix)
- **Minor**: New features (`feat:` prefix)
- **Patch**: Bug fixes and other changes (`fix:`, `chore:`, `docs:`, etc.)

### ✅ Conventional Commit Support
The workflow analyzes commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Supported types:**
- `feat`: New features (minor version bump)
- `fix`: Bug fixes (patch version bump)
- `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `build`: Maintenance (patch version bump)
- `!` suffix or `BREAKING CHANGE`: Breaking changes (major version bump)

### ✅ Gitflow Compliance
- Release branches are created using `git flow release start <version>`
- Branch naming follows gitflow convention: `release/<version>`
- Version updates are committed to the release branch before creating the PR

### ✅ Multi-workspace Support
The workflow manages versions independently for each workspace:

- `src/act`
- `src/common-utils`
- `src/githooks`
- `src/gitutils`
- `src/gitversion`
- `src/larasets`
- `src/pecl`

Each workspace's `devcontainer-feature.json` file contains its own version field that is updated independently.

## Usage

### Manual Trigger
The workflow is designed to be triggered manually via GitHub Actions:

1. Go to the **Actions** tab in your GitHub repository
2. Select **"Multi-workspace Release Automation"**
3. Click **"Run workflow"**
4. Optionally enable **"Dry run mode"** to preview changes without making them
5. Click **"Run workflow"**

### Dry Run Mode
When enabled, dry run mode will:
- Analyze all workspaces and detect changes
- Calculate version bumps
- Show what would be updated
- **Not create any branches, commits, or PRs**

This is useful for testing and previewing releases.

## Workflow Process

1. **Checkout & Setup**: Fetches the repository with full history and sets up required tools
2. **Workspace Analysis**: For each workspace:
   - Detects changes since the last release tag
   - Analyzes conventional commit messages
   - Determines the appropriate version bump
3. **Release Branch Creation**: Creates a gitflow release branch before any version updates
4. **Version Updates**: Updates `devcontainer-feature.json` for each affected workspace
5. **Commit & Push**: Commits version changes to the release branch
6. **Pull Request**: Creates an automated PR to merge the release branch into main

## Example Output

When the workflow runs, it will:

1. **Analyze changes**:
   ```
   [INFO] Analyzing changes for workspace: githooks
   [INFO] Last release tag for githooks: githooks-5.11.3
   [INFO] Commits affecting githooks:
     - feat(githooks): add new pre-push validation
   [SUCCESS] Version update for githooks: 5.11.3 -> 5.12.0 (minor)
   ```

2. **Create release branch**:
   ```
   [INFO] Creating release branch: release/1.1.0
   [INFO] Updating src/githooks/devcontainer-feature.json to version 5.12.0
   ```

3. **Generate PR with detailed information**:
   - Release version and branch information
   - List of updated workspaces with version changes
   - Commit analysis summary

## Configuration

### GitVersion Configuration
The workflow uses GitVersion with the configuration from `.gitversion`:

```
major-version-bump-message: "^(build|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\([\\w\\s-]*\\))?(!:|:.*\\n\\n((.+\\n)+\\n)?BREAKING CHANGE:\\s.+)"
minor-version-bump-message: "^(feat)(\\([\\w\\s-]*\\))?:"
patch-version-bump-message: "^(build|ci|docs|fix|perf|refactor|revert|style|test)(\\([\\w\\s-]*\\))?:"
```

### Workspace Definition
Workspaces are defined in the script as directories under `src/` containing `devcontainer-feature.json` files.

## Benefits

- **Automated Version Management**: No manual version updates required
- **Consistent Release Process**: Follows gitflow and semantic versioning standards
- **Selective Updates**: Only updates workspaces that have actually changed
- **Audit Trail**: Clear commit history and PR descriptions showing what changed
- **Safe Preview**: Dry run mode for testing changes
- **Standards Compliance**: Enforces conventional commit standards

## Troubleshooting

### Common Issues

1. **"No changes detected"**: Ensure commits follow conventional commit format
2. **"Release branch already exists"**: Previous release may not have been completed
3. **"Permission denied"**: Ensure the workflow has `contents: write` and `pull-requests: write` permissions

### Manual Cleanup

If a release branch needs to be cleaned up manually:

```bash
git branch -D release/<version>
git push origin --delete release/<version>
```

## Contributing

When contributing to this repository:

1. Use conventional commit messages
2. Include the workspace scope when relevant: `feat(githooks): add new feature`
3. Use `!` suffix or include `BREAKING CHANGE:` for breaking changes
4. Test changes using dry run mode before creating actual releases

## Related Files

- `.github/workflows/multi-workspace-release.yml`: GitHub Actions workflow definition
- `.github/scripts/multi-workspace-release.sh`: Main release automation script
- `.gitversion`: GitVersion configuration for semantic versioning
- `package.json`: Root package configuration with workspace definitions