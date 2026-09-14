#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

### Husky's own init (configure-husky.sh, via `npx husky`) creates .husky/
### and points core.hooksPath at it - just generate the hook files here.
mkdir -p .husky

### One thin wrapper per hook, delegating logic to the corresponding
### git-hook-<name> command (installed on PATH as a devDependency from
### tomgrv/scripts). No internal hyphens in <name>, e.g. pre-commit ->
### git-hook-precommit.
for hook in pre-commit prepare-commit-msg commit-msg post-checkout post-merge pre-push; do
    command=$(printf '%s' "$hook" | tr -d '-')
    cat >".husky/$hook" <<EOF
#!/bin/sh
# Skip silently if not yet installed (e.g. package.json changed without a
# following \`npm install\`) rather than hard-failing the git operation.
command -v git-hook-$command >/dev/null 2>&1 || exit 0
git-hook-$command "\$@"
EOF
    chmod +x ".husky/$hook" && zz_log s "Generated {U .husky/$hook} calling {U git-hook-$command}"
done
