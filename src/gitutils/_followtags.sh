#!/bin/sh

# Function to print help and manage arguments
eval $(
    zz_args "Manage tag v1.2.3 and following tags v1.2 & v1" $0 "$@" <<-help
		    - tag      tag        Tag to create or follow
	help
)

if [ -n "$tag" ]; then

    # Ensure tag starts with the configured prefix, defaulting to "v"
    prefix=$(git config gitflow.prefix.versiontag || echo "v")
    tag=$(echo "$tag" | sed -E "s/^([0-9.]+)/$prefix\1/g; s/^[^${prefix:-0-9}]//")

    # Check if the tag already exists in the repository
    found=$(git tag --sort=v:refname | grep "$tag" | tail -n1)

    if [ -z "$found" ]; then
        zz_log w "No tags found in the repository, creating a new tag: $tag"
        git tag -a "$tag" -m "$tag"
    else
        zz_log i "Tag $tag already exists as $found, following it"
        tag=$found
    fi
else
    # If no tag is specified, find the latest tag in the repository
    tag=$(git tag --sort=v:refname | tail -n1)
    zz_log s "Latest tag found: $tag"
fi

zz_log i "Make dependent tags point to the same commit as $tag"

# Force update dependent tags
git tag -f $(echo $tag | cut -d. -f1) $tag
git tag -f $(echo $tag | cut -d. -f1-2) $tag

zz_log i "Pushing tags to the remote repository"
git push --tags --force
