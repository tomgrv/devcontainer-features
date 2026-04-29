#!/bin/sh

# Handle parameters
eval $(
	zz_args "Discard changes made only of blanks and quote/slash swaps" $0 "$@" <<-help
		d -         dryrun      show files that would be discarded without changing them
	help
)

# Navigate to repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null || exit 1

# Temp workspace for normalized comparisons
temp_dir=$(mktemp -d)
changed_list="$temp_dir/changed-files.list"
trap 'rm -rf "$temp_dir"' EXIT

# Compare all tracked modified files from HEAD to working tree/index
git diff --name-only --diff-filter=M HEAD -- >"$changed_list"

if [ ! -s "$changed_list" ]; then
	zz_log i "No modified tracked files found."
	exit 0
fi

normalize_file() {
	# Ignore all blank characters and normalize quote/slash variants.
	sed -e 's/[[:space:]]//g' -e "s/[\"']/\"/g" -e 's#[\\/]#/#g' "$1"
}

discarded=0
kept=0
skipped=0

while IFS= read -r file; do
	# Ensure the file still exists in the working tree.
	if [ ! -f "$file" ]; then
		skipped=$((skipped + 1))
		continue
	fi

	old_file="$temp_dir/old-$discarded-$kept-$skipped"
	new_file="$temp_dir/new-$discarded-$kept-$skipped"
	norm_old="$temp_dir/norm-old-$discarded-$kept-$skipped"
	norm_new="$temp_dir/norm-new-$discarded-$kept-$skipped"

	if ! git show "HEAD:$file" >"$old_file" 2>/dev/null; then
		skipped=$((skipped + 1))
		continue
	fi

	cp "$file" "$new_file"

	# Ignore non-text files.
	if ! grep -Iq . "$old_file" || ! grep -Iq . "$new_file"; then
		skipped=$((skipped + 1))
		continue
	fi

	normalize_file "$old_file" >"$norm_old"
	normalize_file "$new_file" >"$norm_new"

	if cmp -s "$norm_old" "$norm_new"; then
		discarded=$((discarded + 1))
		zz_log i "Discarding ignorable-only changes in $file"
		if [ -z "$dryrun" ]; then
			git checkout HEAD -- "$file"
		fi
	else
		kept=$((kept + 1))
	fi
done <"$changed_list"

if [ -n "$dryrun" ]; then
	zz_log s "Dry run complete. Discardable files: $discarded, kept: $kept, skipped: $skipped"
else
	zz_log s "Done. Discarded: $discarded, kept: $kept, skipped: $skipped"
fi
