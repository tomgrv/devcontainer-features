#!/bin/bash

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Normalize JSON according to schema" $0 "$@" <<-help
        w -         write	    write normalized json to original file
        t tabSize   tabSize	    tab size for indentation
        c -         cache	    allow caching of schema validation map
        a -         allow	    allow additional properties at root level
        d -         debug	    debug output
        f fallback  fallback	fallback schema to use if none found locally
        l local     local	    infer schema in <local> folder from json file name (x.y.json => <local>/y.schema.json)
        i -         import	    infer on schema store if nothing found locally (x.y.json => "y" on schema store)
        s schema	schema		schema to use for normalization
        + files	    files		jsons to normalize
        
help
)

for file in $files; do

    # Validate JSON
    zz_log i "Normalizing {U $file}..."
    list=$(validate-json ${allow:+-a} ${cache:+-c} ${debug:+-d} ${fallback:+-f "$fallback"} ${local:+-l "$local"} ${import:+-i} ${schema:+-s"$schema"} $file)

    if test -z "$list"; then
        zz_log e "JSON {U $file} not valid, cannot normalize" && exit 1
    fi

    # Normalize JSON
    zz_json $file | jq -r --arg list "$list" '
        def transform($lst):
            $lst | split("\n") 
                | map(select(length > 0))
                | map(
                   split(".") | map(fromjson)
                );
        def xpath($ary):
            . as $in
            | if ($ary|length) == 0 then null
                else $ary[0] as $k
                    | if $k == []
                        then range(0;length) as $i | $in[$i] | xpath($ary[1:]) | [$i] + .
                        else .[$k] | xpath($ary[1:]) | [$k] + . 
                        end
                end;
        def paths($ary): $ary[] as $path | xpath($path);
        def traverse($paths): 
            . as $in
            | reduce paths($paths) as $p 
                (null; setpath($p; $in 
                            | getpath($p)
                            | if type == "object" then with_entries(.key |= .)
                            | to_entries
                            | sort_by(.key)
                            | from_entries else . end
                        )
                );
        traverse(transform($list))' >/tmp/$$.json

    # Handle output
    if test -s /tmp/$$.json; then
        if test -z "$write"; then
            jq -C --indent ${tabSize:-2} . /tmp/$$.json
        else
            jq -M --indent ${tabSize:-4} . /tmp/$$.json >$file
        fi
        zz_log s "File {U $file} normalized"
    else
        zz_log e "File {U $file} not normalized"
    fi

    # Clean up
    rm -f /tmp/$$.*
done
