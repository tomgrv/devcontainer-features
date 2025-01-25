<!-- @format -->

# Git Utils

This feature provides a set of utilities for working with Git repositories.

The following aliases are included: [./alias.json](./src/gitutils/alias.json)

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description                         | Type   | Default Value |
| ---------- | ----------------------------------- | ------ | ------------- |
| version    | The version of GitUtils to install. | string | latest        |

## GitFlow

Additionally, the feature installs the [git-flow](https://github.com/nvie/gitflow) extension and sets up the Git configuration to use it.

Shortcuts are also added to the `git` command to make it easier to use the `git-flow` commands:

-   `git beta` is a shortcut for `git flow release start`
-   `git hfix` is a shortcut for `git flow hotfix start`
-   `git prod` is a shortcut for `git flow release finish` and `git flow hotfix finish`

These shortcuts work in conjunction with the `gitversion` utility to automatically update the version number of the application.

## Interactive Utilities

The feature includes the following interactive utilities:

-   `git fixup` - Amend the specified commit with current changes and rebase
-   `git align` - Align the current branch with its remote counterpart.
-   `git degit <repository> [directory]` - Download and extract a repository from GitHub, GitLab, or Bitbucket.
-   `git fixup [--force|<commit>]` - Amend the specified commit with current changes and rebase.
-   `git forall <command>` - Execute a command for all files in the repository.
-   `git getcommit [--force|<commit>]` - Get the commit to fixup.
-   `git integrate` - Integrate modifications from the remote repository.
-   `git movetags` - Move tags to the nearest commit with the same message in the current branch.
-   `git release-beta` - Start a new release branch using Git Flow.
-   `git release-hotfix` - Start a new hotfix branch using Git Flow.
-   `git release-prod` - Finish a release or hotfix branch using Git Flow.
-   `git setrights` - Set permissions for files and directories according to best practices.
-   `git unset <prefix> [--local|--global|--system]` - Unset all Git config keys starting with the given prefix.

## Aliases

The following aliases are provided to enhance your Git workflow:

-   `git amend` - Amend the last commit with the current changes.
-   `git beta` - Start a new release branch using Git Flow.
-   `git cleanup` - Stash all changes, clean the working directory, and apply the stash.
-   `git co <message>` - Commit with the provided message.
-   `git conflict` - List files with merge conflicts.
-   `git continue` - Continue the rebase process after resolving conflicts.
-   `git crush` - Stash all changes, reset to the upstream branch, and apply the stash.
-   `git edit` - Amend the last commit and edit the commit message.
-   `git fixMode` - Apply the reverse diff of the current changes.
-   `git fixable` - List commits that can be fixed up.
-   `git forceable` - List commits that can be force-pushed.
-   `git go <message>` - Commit all changes with the provided message.
-   `git hfix` - Start a new hotfix branch using Git Flow.
-   `git histo` - Show the commit history from the last merge.
-   `git ignore <file>` - Add the specified file to `.gitignore` and remove it from the index.
-   `git initFrom <repo> <dir>` - Clone a repository and set up branches.
-   `git isChanged <file>` - Check if the specified file has changed.
-   `git isDirty <file>` - Check if the specified file has uncommitted changes.
-   `git isFixup` - Check if the last commit is a fixup commit.
-   `git isRebase` - Check if a rebase is in progress.
-   `git prod` - Finish a release or hotfix branch using Git Flow.
-   `git recallId <key>` - Set the Git user name and email to the author of the last commit.
-   `git renameTag <old> <new>` - Rename a tag.
-   `git stack` - Amend the last commit without changing the commit message.
-   `git sync` - Fetch and merge changes from the upstream branch.
-   `git undo` - Undo the last commit, keeping the changes in the working directory.

## Customizations

The feature also includes the following VS Code customizations:

-   Extensions:

    -   `donjayamanne.githistory`
    -   `tomblind.scm-buttons-vscode`
    -   `mhutchie.git-graph`
    -   `arturock.gitstash`
    -   `github.copilot`
    -   `github.copilot-chat`
    -   `github.vscode-github-actions`
    -   `gitHub.vscode-pull-request-github`
    -   `github.codespaces`
    -   `waderyan.gitblame`

-   Settings:
    -   `explorer.excludeGitIgnore`: `true`
    -   `git.autorefresh`: `true`

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
