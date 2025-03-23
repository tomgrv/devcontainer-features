#!/bin/bash

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Normalize JSON according to schema" $0 "$@" <<-help
        s -         save	    save normalized json to original file
        t tabSize   tabSize	    tab size for indentation
        a -         allow	    allow additional properties at root level
        d -         debug	    debug output
        f fallback  fallback	fallback schema to use if none found locally
        l local     local	    infer schema in <local> folder from json file name (x.y.json => <local>/y.schema.json)
        i -         import	    infer on schema store if nothing found locally (x.y.json => "y" on schema store)
        - json	    json		json to normalize
        + schema	schema		schema to use for normalization
help
)

# Validate JSON
zz_log i "Normalizing JSON..."
list=$(validate-json ${allow:+-a} ${debug:+-d} ${fallback:+-f "$fallback"} ${local:+-l "$local"} ${import:+-i} "$json" "$schema")

if test -z "$list"; then
    zz_log e "JSON {U $json} not valid, cannot normalize" && exit 1
fi

# Normalize JSON
zz_json $json | jq -r --arg list "$list" '
        def transform($lst):
            $lst | split("\n") 
                | map(select(length > 0))
                | map(
                    split("\".\"") 
                    | map(gsub("^\"|\"$"; "") | select(length > 0))                   
                );
        def xpath($ary):
            . as $in
            | if ($ary|length) == 0 then null
                else $ary[0] as $k
                | if $k == []
                then range(0;length) as $i | $in[$i] | xpath($ary[1:]) | [$i] + .
                else .[$k] | xpath($ary[1:]) | [$k] + . 
                end
                end ;
        def paths($ary): $ary[] as $path | xpath($path);
        def traverse($paths): 
            . as $in
            | reduce paths($paths) as $p 
                (null; setpath($p; $in | getpath($p)));
        
        traverse(transform($list))' >/tmp/$$.json

# Handle output
if test -s /tmp/$$.json; then
    if test -z "$save"; then
        jq -C --indent ${tabSize:-2} . /tmp/$$.json
    else
        jq -M --indent ${tabSize:-4} . /tmp/$$.json >$json
    fi
    zz_log s "File {U $json} normalized"
else
    zz_log e "File {U $json} not normalized"
fi

# Clean up
rm -f /tmp/$$.*
