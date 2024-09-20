#!/bin/sh

## Do not fixup if staged files contains composer.lock or package-lock.json
if [ -n "$(git diff --cached --name-only | grep -E 'composer.lock|package-lock.json')" ]; then
	echo 'Packages lock file are staged, fixup is not allowed.'
	exit 1
fi

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### INTEGRATE MODIFICATIONS
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

#### LOAD PARAMETER
if [ "$1" = '--help' ]; then
	echo 'Usage: git fixup [--force] [<commit>]'
	exit 0
fi

#### CHECK IF FIXUP COMMIT EXISTS
echo 'Check if fixup commit exists...'
if ! git isFixup; then

	## Do not fixup if no files are staged
	if [ -z "$(git diff --cached --name-only)" ]; then
		echo 'No files are staged, fixup is not allowed.'
		exit 1
	fi

	#### LOOK FOR COMMIT TO FIXUP IF NOT GIVEN AS PARAMETER OR IF --force IS USED
	if [ "$1" = "--force" ]; then
		#### GET COMMIT TO FIXUP
		echo 'Get commit to fixup by overwritting pushed history...'
		git forceable
		read -p 'What commit to fix? ' sha
	elif [ -z "$1" ]; then
		echo 'Get commit to fixup without overwritting pushed history...'
		git fixable
		read -p 'What commit to fix? ' sha
	else
		#### USE COMMIT TO FIXUP FROM PARAMETER
		sha=$1
	fi

	#### DISPLAY COMMIT TO FIXUP
	echo 'Fixup commit given:' $sha

	## Create fixup commit and exit if commit is not done
	if ! git commit --fixup $sha --no-verify; then
		echo 'Fixup commit failed...'
		exit 1
	fi

	#### START REBASE
	git rebase -i --autosquash $sha~ --autostash --no-verify
else
	echo -e "\e[32mExisting !fixup commit found. Continue rebasing...\e[0m"

	#### STAGE CONFLICTED FILES AND CONTINUE REBASE
	git add --update && git rebase --continue
fi

#### BACK
cd - >/dev/null
