<!-- @format -->

# Git Hooks

This feature provides a set of hooks for working with Git repositories.

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/githooks:1": {}
}
```

## Configuration

All hooks utilities are installed globally and can be configured in the `package.json` file.

A default configuration is provided for each utility, but you can override it by modifying the `package.json` file.

## Hooks

The following hooks are provided:

-   `pre-commit` - Executes `git-pre-commit` to validate the code before committing. It also runs `lint-staged` to lint and format staged files, ensuring code quality and consistency before changes are committed.
-   `prepare-commit-msg` - Utilizes `commitizen` to help prepare standardized and conventional commit messages, making it easier to follow commit message guidelines.
-   `commit-msg` - Runs `commitlint` to validate commit messages against defined rules, ensuring that all commit messages are consistent and follow the project's conventions.
-   `post-merge` - Handles changes in `package.json` and `composer.json` after a merge, ensuring that dependencies are correctly updated and any necessary post-merge tasks are performed.
-   `post-checkout` - Executes `git update` to synchronize the current branch with the latest changes from the remote repository, keeping the local branch up-to-date.
-   `pre-push` - Runs `validate-branch-name` to ensure that the branch name adheres to the project's naming conventions before pushing changes to the remote repository.

## Customizations

The feature also includes the following VS Code customizations:

-   Extensions:

    -   `vivaxy.vscode-conventional-commits`
    -   `softwareape.rebaser`
    -   `tomblind.scm-buttons-vscode`

-   Settings:
    -   `conventionalCommits.gitmoji`: `false`

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
