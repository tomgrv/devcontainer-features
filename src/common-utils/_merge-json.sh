#!/bin/sh
set -e

script_dir=$(dirname "$(readlink -f "$0")")

# Source colors script
. "$script_dir/_zz_colors.sh"

# Manage arguments
eval $(
    "$script_dir/_zz_args.sh" "Merge 2 json files" $0 "$@" <<-help
        t tabSize     tabSize   tab size for indentation
        - target      target		Target JSON file to merge into
        - source      source		Source JSON file to merge from
help
)

# Validate arguments
if [ -z "$target" ] || [ -z "$source" ]; then
    "$script_dir/_zz_log.sh" e "Usage: json-merge <target> <source>"
    exit 1
fi

# Validate target file
if [ ! -f "$target" ]; then
    "$script_dir/_zz_log.sh" e "Target file {U $target} not found"
    exit 1
elif ! jq empty "$target" >/dev/null 2>&1; then 
    "$script_dir/_zz_log.sh" e "Target file {U $target} is not a valid JSON"
    exit 1
fi

# Validate source file
if [ $source = "-" ]; then
    source=/dev/stdin
fi

"$script_dir/_zz_log.sh" i "Merging JSON from {U $source} into {U $target}..."

# Merge the source JSON into the target JSON
jq 'def merge($a; $b):
  if ($a | type) == "object" and ($b | type) == "object" then
    reduce (($a + $b) | keys_unsorted[]) as $k ({};
      .[$k] =
        if ($a | has($k)) then
          if ($a[$k] | type) == "array" and ($b[$k] | type) == "array" then
            $a[$k] + $b[$k] | unique
          else
            merge($a[$k]; $b[$k])
          end
        else
          $b[$k]
        end
    )
  else
    $a
  end;

merge(.; input)' $target $source | "$script_dir/_normalize-json.sh" -c -a -i -t ${tabSize:-4} -f local -l true 2>/dev/null > /tmp/$$.merge && mv /tmp/$$.merge $target && "$script_dir/_zz_log.sh" s "JSON merged successfully"
