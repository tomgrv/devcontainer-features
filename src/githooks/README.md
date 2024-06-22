<!-- @format -->

# Git Hooks

This feature provides a set of hooks for working with Git repositories.

The following hooks are included:

-   `pre-commit` - Runs `git-pre-commit` to validate the code before committing and `lint-staged` to lint and format staged files
-   `prepare-commit-msg` - Runs `commitizen` to prepare commit messages
-   `commit-msg` - Runs `commitlint` to validate commit messages
-   `post-merge` - Handle changes in package.json and composer.json after a merge
-   `post-checkout` - Runs `git update` to update the current branch with the latest changes from the remote
-   `pre-push` - Runs `validate-branch-name` to validate the branch name before pushing

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/githooks:1": {}
}
```

## Configuration

All hooks utilities are installed globally and can be configured in the `package.json` file.

A default configuration is provided for each utility, but you can override it by modifying the `package.json` file.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
