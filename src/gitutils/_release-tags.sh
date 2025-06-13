#!/bin/sh

# Function to print help and manage arguments
eval $(
    zz_args "Manage tag & following tags" $0 "$@" <<-help
            f -        force      Force tag creation even if it exists
            t -        prefix     Prefix to use for the tag (default: v)
		    - tag      tag        Tag to create or follow
	help
)

if [ -z "$prefix" ]; then
    prefix=$(git config gitflow.prefix.versiontag || echo "v")
fi

if [ -n "$tag" ]; then

    # Ensure tag starts with the configured prefix, defaulting to "v"

    tag=$(echo "$tag" | sed -E "s/^([0-9.]+)/$prefix\1/g; s/^[^${prefix:-0-9}]//")

    # Check if the tag already exists in the repository
    found=$(git tag --sort=v:refname | grep "$tag" | tail -n1)
else
    # If no tag is specified, use gitversion to find the release tag
    tag=$prefix$(gitversion -config .gitversion -showvariable SemVer)
    zz_log s "Tag from gitversion: $tag"
fi

# Create tag if needed
if [ -z "$found" ]; then
    zz_log w "No tags found in the repository, creating a new tag: $tag"
    npx --yes commit-and-tag-version --no-verify --release-as "$tag" ${prefix:+--t "$prefix"} ${force:+---tag-force}
    zz_log i "Tag $tag created successfully"

else
    zz_log i "Tag $tag already exists as $found, following it"
    tag=$found
fi

# If tag is a main version tag (ie: can start with prefix but does not have an hyphen), create dependent tags
if echo "$tag" | grep -qv "-"; then
    zz_log i "Creating dependent tags for $tag"

    # Force update dependent tags
    git tag -f $(echo $tag | cut -d. -f1) $tag
    git tag -f $(echo $tag | cut -d. -f1-2) $tag

else
    zz_log i "No dependent tags created for $tag"
fi

zz_log i "Pushing tags to the remote repository"
git push --tags --force
