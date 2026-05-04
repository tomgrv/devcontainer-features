#!/bin/sh
set -e

# Source colors script
. zz_colors

# Manage arguments
eval $(
    zz_args "Merge 2 json files" $0 "$@" <<-help
        - target      target		Target JSON file to merge into
        - source      source		Source JSON file to merge from
help
)

# Validate arguments
if [ -z "$target" ] || [ -z "$source" ]; then
    zz_log e "Usage: json-merge <target> <source>"
    exit 1
fi

# Validate target file
if [ ! -f "$target" ]; then
    zz_log e "Target file {U $target} not found"
    exit 1
elif ! jq empty "$target" >/dev/null 2>&1; then 
    zz_log e "Target file {U $target} is not a valid JSON"
    exit 1
fi

# Validate source file
if [ $source = "-" ]; then
    source=/dev/stdin
fi

zz_log i "Merging JSON from {U $source} into {U $target}..."

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

merge(.; input)' $target $source |  normalize-json -c -a -i -f local -l true 2>/dev/null > /tmp/$$.merge && mv /tmp/$$.merge $target && zz_log s "JSON merged successfully"
