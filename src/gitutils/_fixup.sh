#!/bin/sh

## Do not fixup if staged files contains composer.lock or package-lock.json
if [ -n "$(git diff --cached --name-only | grep -E 'composer.lock|package-lock.json')" ]; then
	echo 'Packages lock file are staged, fixup is not allowed.'
	exit 1
fi

## Do not fixup if no files are staged
if [ -z "$(git diff --cached --name-only)" ]; then
	echo 'No files are staged, fixup is not allowed.'
	exit 1
fi

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### INTEGRATE MODIFICATIONS
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

#### CHECK IF FIXUP COMMIT EXISTS
echo 'Check if fixup commit exists...'
if ! git isFixup; then

	#### LOOK FOR COMMIT TO FIXUP IF NOT GIVEN AS PARAMETER
	if [ -z "$1" ]; then
		#### GET COMMIT TO FIXUP
		echo 'Get commit to fixup...'
		git histo
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
	echo -e "\e[32mExisting !fixup commit found. Cannot proceed\e[0m"
fi

#### BACK
cd - >/dev/null
