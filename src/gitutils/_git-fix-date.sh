#!/bin/sh

# Function to print help and manage arguments
eval $(
	zz_args "Fix commit dates and times in git history" $0 "$@" <<-help
		f -         force       allow overwriting pushed history
		p -         push        push changes after rewriting history
		d days      days        days of week to reschedule (0=Sunday, 1=Monday, ..., 6=Saturday, comma-separated)
		s start     start       start time for rescheduling (HH:MM format, e.g., 08:00)
		e end       end         end time for rescheduling (HH:MM format, e.g., 20:00)
		b before    before      time to move first half commits to (HH:MM format)
		a after     after       time to move second half commits to (HH:MM format)
		- sha       sha         sha commit to fix from
	help
)

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

# Make sure we don't have uncommitted changes
if ! git diff-index --quiet HEAD --; then
	zz_log e "You have uncommitted changes. Please commit or stash them before running this script."
	exit 1
fi

# Retrieve the commit SHA to fix from
if command -v git-getcommit >/dev/null 2>&1 || git getcommit -h >/dev/null 2>&1; then
	sha=$(git getcommit $force $sha)
elif [ -z "$sha" ] && [ -z "$force" ]; then
	# If no sha provided and no force flag, list fixable commits
	zz_log i "Listing commits that haven't been pushed yet:"
	git log --oneline @{u}..HEAD 2>/dev/null || git log --oneline HEAD~5..HEAD
	read -p 'Which commit SHA to start from? (leave empty for all commits) ' sha
fi

# Validate rescheduling parameters
if [ -n "$days" ] || [ -n "$start" ] || [ -n "$end" ]; then
	if [ -z "$days" ] || [ -z "$start" ] || [ -z "$end" ] || [ -z "$before" ] || [ -z "$after" ]; then
		zz_log e "For rescheduling, you must provide all parameters: -d days, -s start, -e end, -b before, -a after"
		exit 1
	fi
	
	# Validate time formats
	if ! echo "$start" | grep -qE '^[0-9]{2}:[0-9]{2}$'; then
		zz_log e "Invalid start time format. Use HH:MM (e.g., 08:00)"
		exit 1
	fi
	if ! echo "$end" | grep -qE '^[0-9]{2}:[0-9]{2}$'; then
		zz_log e "Invalid end time format. Use HH:MM (e.g., 20:00)"
		exit 1
	fi
	if ! echo "$before" | grep -qE '^[0-9]{2}:[0-9]{2}$'; then
		zz_log e "Invalid before time format. Use HH:MM (e.g., 07:30)"
		exit 1
	fi
	if ! echo "$after" | grep -qE '^[0-9]{2}:[0-9]{2}$'; then
		zz_log e "Invalid after time format. Use HH:MM (e.g., 20:30)"
		exit 1
	fi
	
	# Convert days to array for bash processing
	days_array=$(echo "$days" | tr ',' ' ')
	
	zz_log i "Rescheduling commits on days: $days (0=Sunday, 6=Saturday)"
	zz_log i "Time range: $start - $end"
	zz_log i "First half ($start - midpoint) will move to before $before"
	zz_log i "Second half (midpoint - $end) will move to after $after"
fi

#### Rewrite history to fix dates
zz_log i "Rewriting commit dates from commit $sha"

# Create the date filter script
if [ -n "$days" ]; then
	# Rescheduling mode - need to process commits in two passes
	# First pass: collect commits that need rescheduling
	# Second pass: redistribute them while maintaining sequential order
	
	zz_log i "Analyzing commits for rescheduling..."
	
	# Get list of commits to process
	if [ -n "$sha" ]; then
		commit_range="${sha}..HEAD"
	else
		commit_range="--all"
	fi
	
	# Create a temporary mapping file for new times
	temp_map=$(mktemp)
	trap "rm -f $temp_map" EXIT
	
	# Collect commits that need rescheduling
	git log --format="%H|%ai|%ci" --reverse $commit_range | while IFS='|' read commit_sha author_date committer_date; do
		# Extract date and time components
		a_date=$(echo "$author_date" | cut -d' ' -f1)
		a_time=$(echo "$author_date" | cut -d' ' -f2)
		a_tz=$(echo "$author_date" | cut -d' ' -f3-)
		
		c_date=$(echo "$committer_date" | cut -d' ' -f1)
		c_time=$(echo "$committer_date" | cut -d' ' -f2)
		c_tz=$(echo "$committer_date" | cut -d' ' -f3-)
		
		# Get day of week for author date
		dow=$(date -d "$a_date" +%w 2>/dev/null || echo "")
		
		# Check if this day should be rescheduled
		should_reschedule=0
		for day in $(echo "$days" | tr ',' ' '); do
			if [ "$dow" = "$day" ]; then
				should_reschedule=1
				break
			fi
		done
		
		if [ "$should_reschedule" = "0" ]; then
			# No rescheduling needed
			echo "$commit_sha|$author_date|$committer_date" >> "$temp_map"
			continue
		fi
		
		# Convert time to seconds
		a_seconds=$(echo "$a_time" | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
		start_seconds=$(echo "$start" | awk -F: '{print ($1 * 3600) + ($2 * 60)}')
		end_seconds=$(echo "$end" | awk -F: '{print ($1 * 3600) + ($2 * 60)}')
		
		# Check if time is in the range to reschedule
		if [ "$a_seconds" -ge "$start_seconds" ] && [ "$a_seconds" -le "$end_seconds" ]; then
			# Calculate midpoint
			mid_seconds=$(( (start_seconds + end_seconds) / 2 ))
			
			# Determine new time based on which half of the range
			if [ "$a_seconds" -lt "$mid_seconds" ]; then
				# First half - move to before time
				new_time="$before:00"
			else
				# Second half - move to after time
				new_time="$after:00"
			fi
			
			new_author_date="$a_date $new_time $a_tz"
			new_committer_date="$c_date $new_time $c_tz"
			
			echo "$commit_sha|$new_author_date|$new_committer_date" >> "$temp_map"
		else
			# Not in range, keep as-is
			echo "$commit_sha|$author_date|$committer_date" >> "$temp_map"
		fi
	done
	
	# Export the mapping file path for the filter
	export DATE_MAP_FILE="$temp_map"
	
	date_filter='
		# Look up the new date for this commit
		commit_sha="$GIT_COMMIT"
		map_file="$DATE_MAP_FILE"
		
		if [ -f "$map_file" ]; then
			line=$(grep "^$commit_sha|" "$map_file" || echo "")
			if [ -n "$line" ]; then
				new_author=$(echo "$line" | cut -d"|" -f2)
				new_committer=$(echo "$line" | cut -d"|" -f3)
				
				if [ -n "$new_author" ]; then
					export GIT_AUTHOR_DATE="$new_author"
				fi
				if [ -n "$new_committer" ]; then
					export GIT_COMMITTER_DATE="$new_committer"
				fi
			fi
		fi
	'
else
	# No rescheduling, just preserve dates as-is
	date_filter='
		# Keep dates unchanged - this mode is for future extensions
		export GIT_AUTHOR_DATE="$GIT_AUTHOR_DATE"
		export GIT_COMMITTER_DATE="$GIT_COMMITTER_DATE"
	'
fi

# Execute filter-branch with the date filter
git filter-branch --env-filter "$date_filter" --tag-name-filter cat -- --branches --tags ${sha:---all}${sha:+..HEAD}

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now

# Push changes if the push flag is set
if [ "$push" = true ]; then
	if [ "$force" = true ]; then
		git push --force --tags origin 'refs/heads/*'
	else
		git push --force-with-lease --tags origin 'refs/heads/*'
	fi
fi

zz_log s "Git date fixup completed successfully."
