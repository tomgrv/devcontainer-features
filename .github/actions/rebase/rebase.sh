#!/bin/sh
# Rebase the current PR branch onto its base branch.
# Inspired by https://github.com/cirrus-actions/rebase
# Uses only sh + standard git + gh CLI — no external action dependencies.

set -eu

# ---------------------------------------------------------------------------
# Resolve pull-request metadata via gh CLI
# ---------------------------------------------------------------------------
pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null || true)

if [ -z "$pr_number" ]; then
    echo "::error::Could not resolve the pull request number from the current context."
    exit 1
fi

head_ref=$(gh pr view "$pr_number" --json headRefName --jq '.headRefName')
base_ref=$(gh pr view "$pr_number" --json baseRefName --jq '.baseRefName')
head_repo=$(gh pr view "$pr_number" --json headRepositoryOwner,headRepository --jq '"\(.headRepositoryOwner.login)/\(.headRepository.name)"')

echo "::group::Rebase PR #${pr_number}: ${head_ref} → ${base_ref}"
echo "Head repo : $head_repo"
echo "Head ref  : $head_ref"
echo "Base ref  : $base_ref"
echo "Autosquash: ${AUTOSQUASH:-false}"

# ---------------------------------------------------------------------------
# Configure the remote for the head fork (supports cross-fork PRs)
# ---------------------------------------------------------------------------
current_remote=$(git remote get-url origin 2>/dev/null || true)
head_url="https://x-access-token:${GH_TOKEN}@github.com/${head_repo}.git"

if git remote | grep -q '^head_fork$'; then
    git remote set-url head_fork "$head_url"
else
    git remote add head_fork "$head_url"
fi

# ---------------------------------------------------------------------------
# Fetch both branches with full history
# ---------------------------------------------------------------------------
git fetch --no-tags origin "${base_ref}:refs/remotes/origin/${base_ref}" 2>&1 | sed 's/^/[fetch] /'
git fetch --no-tags head_fork "${head_ref}:refs/remotes/head_fork/${head_ref}" 2>&1 | sed 's/^/[fetch] /'

# ---------------------------------------------------------------------------
# Check whether rebase is actually needed
# ---------------------------------------------------------------------------
base_sha=$(git rev-parse "refs/remotes/origin/${base_ref}")
head_sha=$(git rev-parse "refs/remotes/head_fork/${head_ref}")
merge_base=$(git merge-base "$base_sha" "$head_sha")

if [ "$merge_base" = "$base_sha" ]; then
    echo "::notice::Branch is already up-to-date with ${base_ref} — nothing to do."
    echo "::endgroup::"
    exit 0
fi

# ---------------------------------------------------------------------------
# Perform the rebase on a detached worktree
# ---------------------------------------------------------------------------
git checkout --detach "refs/remotes/head_fork/${head_ref}"

autosquash_flag=""
if [ "${AUTOSQUASH:-false}" = "true" ]; then
    autosquash_flag="--autosquash"
fi

GIT_SEQUENCE_EDITOR=true \
    git rebase \
        --interactive \
        $autosquash_flag \
        --autostash \
        "refs/remotes/origin/${base_ref}"

# ---------------------------------------------------------------------------
# Push the rebased history back (force-with-lease for safety)
# ---------------------------------------------------------------------------
git push head_fork "HEAD:refs/heads/${head_ref}" --force-with-lease="${head_ref}:${head_sha}"

echo "::notice::Successfully rebased ${head_ref} onto ${base_ref}."
echo "::endgroup::"
