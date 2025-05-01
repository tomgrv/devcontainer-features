#!/bin/sh

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
	zz_args "Fix git history" $0 "$@" <<-help
		    f -        force     allow overwritting pushed history
			- sha      sha       sha commit to fixup
	help
)

## Do not fixup if staged files contains composer.lock or package-lock.json
if [ -n "$(git diff --cached --name-only | grep -E 'composer.lock|package-lock.json')" ]; then
	echo 'Packages lock file are staged, fixup is not allowed.'
	exit 1
fi

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Integrate modifications from remote
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

#### Check if fixup commit exists
if git isFixup; then
	zz_log e 'Fixup commit found, please continue rebasing...'
	exit 1
fi

## Do not fixup if no files are staged
if [ -z "$(git diff --cached --name-only)" ]; then
	zz_log e 'No files are staged, fixup is not allowed.'
	exit 1
fi

#### Get commit to fixup
sha=$(git getcommit $sha)

#### Display commit to fixup
zz_log i "Fixup commit given: $sha"

## Create fixup commit and exit if commit is not done
if ! git commit --fixup $sha --no-verify; then
	zz_log e 'Fixup commit failed...'
	exit 1
fi

#### Start rebase
git rebase -i --autosquash $sha~ --autostash --no-verify --exec '[ -f .git/hooks/pre-commit ] && (.git/hooks/pre-commit --name-only HEAD HEAD~1 && git commit --amend --no-edit --no-verify) || true'

#### Back to previous directory
cd - >/dev/null
