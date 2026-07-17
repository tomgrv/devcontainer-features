#!/bin/sh

# Function to print help and manage arguments
eval $(
	zz_args "Redact a secret from files matching a glob across all git history" $0 "$@" <<-help
		f -      force      allow overwriting pushed history
		p -      push       push to remote
		d -      dryrun     list matching commits/files without rewriting history
		g glob   glob       glob pattern of files to search (e.g. "**/*.env")
		s secret secret     secret value to redact
		- sha    sha        sha commit to start from
	help
)

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

# Check if the glob option is set
if [ -z "$glob" ]; then
	glob=$(zz_prompt "Glob pattern of files to search (e.g. **/*.env):")
fi

if [ -z "$glob" ]; then
	zz_log e "A glob pattern is required."
	exit 1
fi

# Check if the secret option is set
if [ -z "$secret" ]; then
	secret=$(zz_prompt "Secret value to redact:")
fi

if [ -z "$secret" ]; then
	zz_log e "A secret value is required."
	exit 1
fi

# Make sure we don't have uncommitted changes
if ! git diff-index --quiet HEAD --; then
	zz_log e "You have uncommitted changes. Please commit or stash them before running this script."
	exit 1
fi

# Prevent running while a rebase is in progress
if git isRebase >/dev/null 2>&1; then
	zz_log e "A rebase is in progress. Please finish or abort it before running this script."
	exit 1
fi

# Build the commit range to process
if [ -n "$sha" ]; then
	sha=$(git rev-parse --verify "$sha^{commit}" | cut -d' ' -f1 | tr -d '\n')
fi

zz_log i "Searching for secret in files matching '$glob'"

matches=$(git grep -I -l -F "$secret" $(git rev-list --branches --tags ${sha:---all}${sha:+..HEAD}) -- "$glob" 2>/dev/null)

if [ -z "$matches" ]; then
	zz_log s "No occurrences of the secret found in matching files."
	exit 0
fi

zz_log - "$matches"

if [ -n "$dryrun" ]; then
	zz_log i "Dry run complete. No changes were made."
	exit 0
fi

zz_log w "This will rewrite git history. Make sure you understand the consequences."
if ! zz_ask "Yn" "Do you want to proceed?"; then
	zz_log i "Operation cancelled by user."
	exit 1
fi

tree_filter='
	git ls-files -- "$GLOB_PATTERN" | while IFS= read -r file; do
		[ -f "$file" ] || continue
		grep -Iq . "$file" 2>/dev/null || continue
		node -e "
			const fs = require(\"fs\");
			const file = process.argv[1];
			const secret = process.env.SECRET_VALUE;
			const data = fs.readFileSync(file, \"utf8\");
			if (data.includes(secret)) {
				fs.writeFileSync(file, data.split(secret).join(\"****\"));
			}
		" "$file"
	done
'

export GLOB_PATTERN="$glob"
export SECRET_VALUE="$secret"

git filter-branch $force --tree-filter "$tree_filter" --tag-name-filter cat -- --branches --tags ${sha:---all}${sha:+..HEAD}

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now

if [ -n "$push" ]; then
	zz_log i "Pushing changes to remote"
	git push --force --progress --recurse-submodules=no origin --all
	git push --force --progress --recurse-submodules=no origin --tags
else
	zz_log w "Changes are not pushed to remote, use -p option to push"
fi

zz_log s "Secret redacted from history."
