#!/bin/sh

## Do not fixup if staged files contains composer.lock or package-lock.json
if [ -n "$(git diff --cached --name-only | grep -E 'composer.lock|package-lock.json')" ]; then
	echo 'Packages lock file are staged, fixup is not allowed.'
	exit 1
fi

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Integrate modifications from remote
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

#### Display help
if [ "$1" = '--help' ]; then
	echo 'Usage: git fixup [--force|<commit>]'
	exit 0
fi

#### Check if fixup commit exists
echo 'Check if fixup commit exists...'
if ! git isFixup; then

	## Do not fixup if no files are staged
	if [ -z "$(git diff --cached --name-only)" ]; then
		echo 'No files are staged, fixup is not allowed.'
		exit 1
	fi

	#### Get commit to fixup
	sha=$(git getcommit "$@")

	#### Display commit to fixup
	echo 'Fixup commit given:' $sha

	## Create fixup commit and exit if commit is not done
	if ! git commit --fixup $sha --no-verify; then
		echo 'Fixup commit failed...'
		exit 1
	fi

	#### Start rebase
	git rebase -i --autosquash $sha~ --autostash --no-verify --exec '[ -f .git/hooks/pre-commit ] && (.git/hooks/pre-commit --name-only HEAD HEAD~1 && git commit --amend --no-edit --no-verify) || true'
else
	echo -e "\e[32mExisting !fixup commit found. Continue rebasing...\e[0m"

	#### Stage all changes
	git add --update && git rebase --continue
fi

#### Back to previous directory
cd - >/dev/null
