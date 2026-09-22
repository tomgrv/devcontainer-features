#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# .gitattributes declares "*.json merge=json" and "*.yaml/*.yml merge=yaml",
# but a merge driver name is only meaningful once registered under
# merge.<name>.driver in git config — without this, git silently falls
# back to its default 3-way text merge on conflicts. merge-json/merge-yaml
# take (target, source) rather than the driver's usual (base, ours,
# theirs): %A already holds "ours", so the tool reads it as the target,
# merges %B ("theirs") into it in place, and its exit status reports
# success/failure directly to git.
git config merge.json.driver 'merge-json %A %B' && zz_log s "Registered merge.json.driver" || zz_log e "Failed to register merge.json.driver"
git config merge.yaml.driver 'merge-yaml %A %B' && zz_log s "Registered merge.yaml.driver" || zz_log e "Failed to register merge.yaml.driver"
