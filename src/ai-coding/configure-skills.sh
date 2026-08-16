#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0


eval $(
    zz_context "$@"
)

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    zz_log e "jq is not installed. Please install jq to proceed."
    exit 1
fi

zz_log i "Restoring skills from lockfile..."
npx --yes skills experimental_install

zz_log i "Get list of installed skills..."
installed_skills=$(npx --yes skills list --json | jq -r '.[] | .source' | sort -u)

zz_log i "Installing skills in {Purple ${scope:-project}} scope..."

### For each entry in config.json file next to this file, create corresponding git config from key and value.
### if value is an object, parse it as json and create dotted keys
if [ -f "$source/configs/skills.json" ]; then
    
    zz_log i "Configuring skills with {U $source/configs/skills.json}..."

    # get master agent list from skills.json
    master_agents=$(jq -r '.agents // [] | join(",")' "$source/configs/skills.json")

    # list all skills in skills.json as "skill global"
    for entry in $(jq -r '.skills[] | "\(.package);\(.global);\(.agents // [] | join(","))"' "$source/configs/skills.json"); do
        
        # Extract package, global, and sub_agents from the entry
        package=$(echo "$entry" | cut -d';' -f1)
        global=$(echo "$entry" | cut -d';' -f2)
        sub_agents=$(echo "$entry" | cut -d';' -f3)

        if echo "$installed_skills" | grep -q "^$package$"; then
            zz_log i "Skill {B $package} is already installed, skipping..."
            continue
        fi
        
        # Determine the scope based on the global value
        case "$global" in
            true|True|TRUE)
                scope="--global"
                ;;
            false|False|FALSE)
                scope=""
                ;;
            *)
                scope=$SKILLS_SCOPE
                ;;
        esac

        # sub_agents can be a comma-separated list of agents, or empty.
        # sub_agents need to be combined with master_agents to form the final agents list : add, remove if prefixed with !, no duplicates
        if [ -n "$sub_agents" ]; then

            # create temporary file to hold the excluded agents
            exclude_agents=$(mktemp)
            include_agents=$(mktemp)

            # List of agents to exclude (prefixed with !)
            echo "$sub_agents" | tr ',' '\n' | grep '^!' | sed 's/^!//g' > "$exclude_agents"

            # List of agents to include (not prefixed with !)
            echo "$sub_agents" | tr ',' '\n' | grep -v '^!'  > "$include_agents"

            # Remove excluded agents from the master_agents list
            agents=$(echo "$master_agents" | tr ',' '\n' | grep -v -F -f "$exclude_agents")

            # Add included agents from the sub_agents list (not prefixed with !), ensuring no duplicates
            agents=$( (cat "$include_agents"; echo "$agents") | sort -u | tr '\n' ' ' )
        else
            agents=$(echo "$master_agents" | tr ',' ' ')
        fi

        zz_log i "Installing skill {B $package} in {Purple ${scope:-project}} scope with agents: {Cyan $agents}..."
        npx --yes skills add "$package" ${scope} --yes  --skill '*' --agent $agents
        zz_log - "Installed skill {B $package} in {Purple ${scope:-project}} scope"
      
    done
fi

# ensure .prettierignore exists in the project root and contains the default .agents entries
if [ ! -f "$repo_root/.prettierignore" ]; then
    echo ".agents/" > "$repo_root/.prettierignore"
    zz_log s "Created .prettierignore file in project root with default .agents entry"
else
    zz_log i "Ensuring .prettierignore file in project root contains default .agents entry..."
    if ! grep -q "^\.agents/$" "$repo_root/.prettierignore"; then
        echo ".agents/" >> "$repo_root/.prettierignore"
        zz_log s "Added .agents entry to .prettierignore"
    fi
fi
