#!/bin/bash

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Normalize JSON according to schema" $0 "$@" <<-help
        s -         save	    save normalized json to original file
        t -         tabSize	    tab size for indentation
        a -         allow	    allow additional properties at root level
        d -         debug	    debug output
        f fallback  fallback	fallback schema to use if none found locally
        l local     local	    infer schema in <local> folder from json file name (x.y.json => <local>/y.schema.json)
        i -         import	    infer on schema store if nothing found locally (x.y.json => "y" on schema store)
        - json	    json		json to normalize
        + schema	schema		schema to use for normalization
help
)

# Check if JSON exists and is readable
if test -z "$json" && test ! -f "$json"; then
    echo -e "${Red}JSON is missing${None}"
    exit 1
fi

# Function to check if input is valid JSON
is_json() {
    jq empty 2>/dev/null
}

# Function to check if JSON is an array
is_json_array() {
    local path=${1:-.}
    is_existing_path "$path" | jq -e 'if type == "array" then . else null end' >/dev/null
}

# Function to check if JSON is an object
is_json_object() {
    local path=${1:-.}
    is_existing_path "$path" | jq -e 'if type == "object" then . else null end' >&2 #>/dev/null
}

# Function to check if JSON contains a $ref
is_json_ref() {
    local path=${1:-.}
    is_existing_path "$path" | jq -e 'if type == "object" and has("$ref") then . else null end' >/dev/null
}

# Function to check if a path exists in JSON
is_existing_path() {
    local path=${1:-.}
    get_path "$path" 2>/dev/null >/dev/null

}

# Function to check if JSON is an array
is_true() {
    local path=${1:-.}
    get_path "$path" -r | jq -e 'if . == true then . else null end' >/dev/null
}

# Function to check if root path and additonal properties are allowed
is_allowed() {
    local path=${1:-.}

    if test "$path" == "."; then
        if test -n "$allow"; then
            echo -e "${lvl}- ${Purple}Additional properties allowed at root level${None}" >&2
            return 0
        else
            echo -e "${lvl}- ${Yellow}Additional properties not allowed at root level${None}" >&2
            return 1
        fi
    fi
}

# Function to get the type of JSON element
get_json_array() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'type | tojson'
}

# Function to get the type of JSON element
get_json_type() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'type | tojson'
}

# Function to get JSON as string
get_json() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'if . == null then {} else . end | tojson'
}

# Function to get the size of a JSON array
get_array_size() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'length'
}

# Function to get items of a JSON array
get_array_items() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'if type == "array" then .[] else . end | tojson'
}

# Function to get keys of a JSON object
get_keys() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'if type == "object" then keys_unsorted else [] end' | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/,$//g' -e 's/^[[:blank:]]*//g' -e '/^$/d'
}

# Function to get value at a given path
get_path() {
    local path=${1:-.}
    local raw=$(test -z "$2" && echo "-r" || echo "")

    jq -e --arg path "$path" $raw '
        def split_path:
            gsub("\\["; ".") | gsub("\\]"; "") | split(".") | map(
                select(length > 0) | gsub("^\"|\"$";"") | if test("^[0-9]+$") then tonumber else . end
            );
        getpath($path | split_path)'
}

# Function to get remove comments from JSON.
# Do not remove comments inside strings.
load_json() {
    local file=${1:--}
    sed -e 's:^[[:blank:]]*//.*$::g' $file
}

load_json_schema() {
    local source=${1:--}
    local file=${2:-$source}

    load_json $file | jq --arg source "$source" 'if $source != "" and has("$id") then . else . + {"$id": $source} end'
}

# Function to check if only one of the properties is valid (only one should be valid)
oneOf_rule() {
    local size=$1
    local count=$2
    local index=$3

    test $count -eq 1
}

# Function to check if all properties are valid (all should be valid)
allOf_rule() {
    local size=$1
    local count=$2
    local index=$3

    test $count -eq $size
}

# Function to check if any of the properties are valid (at least one should be valid)
anyOf_rule() {
    local size=$1
    local count=$2
    local index=$3

    test "$count" -gt "0" && test $index -eq $(expr $size - 1)
}

# Function to get the schema url from schema store
get_schema_url() {
    local name=$1
    local catalog=https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/api/json/catalog.json
    curl -s $catalog | jq -r -e ".schemas[] | select(.name == \"$name\") | .url"
}

# Function to get the schema file from url
get_schema_json() {
    local url=$1

    # Download schema file and add id to it if not present
    curl -s $url | load_json_schema $url -

    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to download schema file $schema${None}" >&2
        exit 1
    fi
}

traverse() {
    local json=$1
    local list=${2:--}

    list=$(cat $list | sed 's/^.//g' | uniq -u)

    load_json $json | jq -r --arg list "$list" '
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
        
        traverse(transform($list))'
}

# Function to parse and validate JSON according to schema
validate() {

    # Arguments
    local json=$1       # JSON to validate (mandatory)
    local schema=$2     # Schema to use (mandatory)
    local path=$3       # Path to schema (optional)
    local real=$4       # Real path in JSON (optional)
    local call=${5:-$3} # Reference flag (optional)
    local not=$6        # Not flag (optional)
    local level=$7      # Recursive level for logs (optional)

    # if json does not start with '{' and is a file, load it
    if test -f "$json"; then
        echo -e "${lvl}${Green}Loading json ${UGreen}$json${None}" >&2
        json=$(load_json $json)
    fi

    # if schema is not a valid JSON, return error
    if ! is_json <<<"$json"; then
        echo -e "${Red}Invalid json${None}" >&2
        exit 1
    fi

    # if schema is a file, load it
    if test -f "$schema"; then
        echo -e "${lvl}${Green}Loading schema ${UGreen}$schema${None}" >&2
        schema=$(load_json_schema $schema)
    fi

    # if schema is a url, download it
    if test -n "$(echo $schema | grep -E '^http')"; then
        echo -e "${lvl}${Green}Downloading schema ${UGreen}$schema${None}" >&2
        schema=$(get_schema_json $schema)
    fi

    # if schema is not a valid JSON, return error
    if ! is_json <<<"$schema"; then
        echo -e "${Red}Invalid schema${None}" >&2
        exit 1
    fi

    # Local Variables
    local entry=""
    local props=""
    local items=""
    local prop=""
    local more=""
    local type=""
    local lvl=""
    local id=$(get_path ".\$id" <<<"$schema")

    # if level is not set, set it to 0
    if test -z "$level"; then
        level=0
    else
        # Increment level
        level=$(expr $level + 1)

        # Set lev helper from level
        for i in $(seq 1 $level); do
            lvl="$lvl  | "
        done
    fi

    # Log
    echo -e "${lvl}${Blue}Parsing schema <${path:-.}> == <${real:-.}>${None} at level <$level>" >&2

    # get 1st level entry points (oneOf, allOf, anyOf, properties) and loop through them
    for entry in '"$id"' '"not"' '"oneOf"' '"allOf"' '"anyOf"' '"type"' '"required"' '"$ref"' '"properties"' '"items"' '"additionalProperties"'; do

        # Use entry if it exists in schema
        if ! is_existing_path "$path.$entry" <<<"$schema"; then
            continue
        fi

        echo -e "${lvl}- Processing <${Blue}${path}:$entry${None}>" >&2

        case $entry in

        \"\$id\")

            #log
            echo -e "${lvl}- Processing ${BWhite}\$id${None}" >&2

            # get id from schema
            id=$(get_json "$path.$entry" <<<"$schema" || echo ".")

            # log
            echo -e "${lvl}- Resolving ${Yellow}$id${None}" >&2
            ;;

        \"\$ref\")

            # get ref from schema by using $id as base path if it exists and ref is a local reference
            local ref=$(get_path "$path.$entry" <<<"$schema")

            if test "$ref" == "null" || test -z "$ref"; then
                echo -e "${Red}Reference not found for $path.$entry${None}" >&2
                exit 1
            fi

            echo -e "${lvl}- Ref is ${Yellow}${ref}${None}" >&2
            echo -e "${lvl}  From ${Yellow}${id}${None}..." >&2

            # separate uri before # from fragment after #
            local uri=$(echo $ref | awk -F '#' '{print $1}')
            local fgt=$(echo $ref | awk -F '#' '{print $2}')

            # if ref is a url, download it and use it as schema
            if test -n "$(echo $uri | grep -E '^http')"; then
                echo -e "${lvl}- Loading ${Yellow}${uri}${None}..." >&2
                schema=$(get_schema_json $uri)
            elif test -n "$uri"; then
                # check if file exists
                if test -f "$uri"; then
                    echo -e "${lvl}- Loading ${Yellow}${uri}${None}..." >&2
                    schema=$(load_json_schema $uri)
                elif test -n "$id"; then
                    # load schema from file
                    echo -e "${lvl}- Loading ${Yellow}$(dirname $id)/$uri${None}..." >&2
                    schema=$(get_schema_json $(dirname $id)/$uri)
                else
                    echo -e "${Red}Unable to resolve reference $ref with $id${None}" >&2
                    exit 1
                fi

            fi

            # if schema is not a valid JSON, return error
            if ! validate "$json" "$schema" "$(echo $fgt | tr '/' '.')" "$real" "$path" "$not" "$level"; then
                echo -e "${lvl}- ${Yellow}Reference $ref is invalid${None}" >&2
                return 1
            fi

            ;;

        \"not\")
            echo -e "${lvl}- ${Purple}Start Not${None}" >&2

            # Parse sub schema with not flag
            if ! validate "$json" "$schema" "$path.$entry" "$real" "$path.$entry" "!" "$level"; then
                echo -e "${lvl}- ${Yellow}Condition is invalid${None}" >&2
                return 1
            fi

            echo -e "${lvl}- ${Purple}End Not${None}" >&2

            ;;

        \"oneOf\" | \"allOf\" | \"anyOf\")

            if ! is_json_array "$path.$entry" <<<"$schema"; then
                echo -e "${Red}Invalid $entry schema${None}" >&2
                exit 1
            fi

            # Loop through array
            local size=$(get_array_size "$path.$entry" <<<"$schema")
            local last=$(expr $size - 1)
            local count=0

            echo -e "${lvl}- ${Cyan}Start $entry loop${None}" >&2

            for i in $(seq 0 $last); do
                if validate "$json" "$schema" "$path.$entry[$i]" "$real" "$path.$entry[$i]" "$not" "$level"; then
                    count=$(expr $count + 1)
                fi
                ${entry//\"/}_rule $size $count $i && break
            done

            echo -e "${lvl}- ${Cyan}End $entry loop ($count/$size)${None}" >&2
            ${entry//\"/}_rule $size $count $last || return 1
            ;;

        \"type\")

            # Log
            echo -e "${lvl}- Processing ${BWhite}Type${None}" >&2

            local type_json=$(get_json_type "$real" <<<"$json")

            for type_schema in $(get_array_items "$path.$entry" <<<"$schema"); do

                # if type is integer, force it to number
                if test "$type_schema" == "\"integer\""; then
                    type_schema="\"number\""
                fi

                # Check if value type matches schema type and log only prop name
                if test "$type_json" != "$type_schema"; then
                    continue
                fi

                # break loop if type is found
                type=$type_schema
            done

            # If no type was found, return error
            if test -z "$type"; then
                echo -e "${lvl}- ${Yellow}Property ${real:-.} is ${type_json}, not of expected type ${type_schema}${None}" >&2
                return 1
            fi

            echo ${real:-.}

            # Log
            echo -e "${lvl}- ${Green}Property ${real:-.} is of expected type ${type}${None}" >&2
            ;;

        \"required\")

            local count=0
            local size=0

            # if type is not an object, do not process
            if test "$type" != "\"object\""; then
                echo -e "${lvl}- ${Yellow}Skip required not an object ($type)${None}" >&2
                continue
            fi

            # loop through required properties
            for prop in $(get_array_items "$path.$entry" <<<"$schema"); do

                size=$(expr $size + 1)

                if is_existing_path "$real.$prop" <<<"$json"; then
                    if test -n "$not"; then
                        echo -e "${lvl}- ${Yellow}Property $prop is present but not required${None}" >&2
                        return 1
                    fi
                else
                    if test -z "$not"; then
                        echo -e "${lvl}- ${Yellow}Property $prop is missing but required${None}" >&2
                        return 1
                    fi
                fi

                echo -e "${lvl}- ${Green}Property requirement is valid for $prop${None}" >&2
            done
            ;;

        \"items\")

            # If items is not an array, do not process
            if test "$type" != "\"array\""; then
                echo -e "${lvl}- ${Yellow}Skip properties not an  ($type)${None}" >&2
                continue
            fi

            # Log
            echo -e "${lvl}- Processing ${BWhite}Items${None}" >&2

            # get items schema
            items=$(get_path "$path.$entry" <<<"$schema")

            # Loop through items
            for item in $(get_keys "$real" <<<"$json" | sort); do

                # Log
                echo -e "${lvl}- Processing item ${Purple}$item${None}" >&2

                if ! validate "$json" "$schema" "$path.$entry" "$real.$item" "$path.$entry" "$not" "$level"; then
                    echo -e "${lvl}- ${Orange}Item $item is invalid${None}" >&2
                    return 1
                fi
            done
            ;;

        \"properties\")

            # If items is not an object, do not process
            if test "$type" != "\"object\""; then
                echo -e "${lvl}- ${Yellow}Skip properties not an object ($type)${None}" >&2
                continue
            fi

            # Log
            echo -e "${lvl}- Processing ${BWhite}Properties${None}" >&2

            # get properties list
            props=$(get_keys "$path.$entry" <<<"$schema" | tr "\n" " ")

            # Log
            #echo -e "${lvl}- Properties are ${Purple}$props${None}" >&2

            # Loop through properties
            for prop in $props; do

                #echo -e "${lvl}- Processing property ${Purple}$prop${None}" >&2
                if $not is_existing_path "$real.$prop" <<<"$json"; then

                    # Log
                    echo -e "${lvl}- Processing <${Purple}$prop${None}>" >&2

                    # Parse sub schema
                    if ! validate "$json" "$schema" "$path.$entry.$prop" "$real.$prop" "$path.$entry.$prop" "$not" "$level"; then
                        echo -e "${Red}Property $prop is present but invalid${Red}" >&2
                        return 1
                    fi
                else
                    # Log
                    echo -e "${lvl}- ${Yellow}Skip property $real.$prop not present${None}" >&2
                fi
            done

            echo "${real:-.}"
            ;;

        \"additionalProperties\")

            echo -e "${lvl}- Processing ${BWhite}Additional properties${None}" >&2
            if is_allowed "$real" || is_existing_path "$path.$entry" <<<"$schema"; then

                echo -e "${lvl}- ${Purple}Additional properties allowed for ${real:-.}${None}" >&2

                for prop in $(get_keys "$real" <<<"$json" | sort); do
                    if ! grep -q "$prop" <<<"$props"; then
                        echo -e "${lvl}- Adding additional property <${Purple}$real.$prop${None}>" >&2

                        # Keep track of validated path
                        echo "$real.$prop"
                    fi
                done
            fi
            ;;
        esac
    done

    # Log
    echo -e "${lvl}${Blue}End Parsing, all valid!${None}" >&2
}

# if local flag is set, get schema from json file name
if [ -n "$local" ]; then

    # Identify package type from file name just before json extension
    type=$(basename -s .json $json | sed -E 's/.*\.(.*)/\1/')

    # Identify schema file
    schema=$local/_$type.schema.json

    # log
    echo -e "${Yellow}Infering schema from local folder for ${UYellow}$json${None}" >&2
fi

# Check if schema file exists, and if not and import allowed, download it from schema store
if [ -n "$import" ] && [ ! -f "$schema" ]; then

    search=$(basename -s .json $json | sed -E 's/.*\.(.*)/\1/').json

    # find schema file url from schema store catalog
    schema=$(get_schema_url $search)

    # log
    echo -e "${Yellow}Infering schema from schema store for ${UYellow}$search${Yellow} ${schema:+"found!"}${None}${None}" >&2
fi

# if schema file does not exist, use fallback schema
if [ -n "$fallback" ] && [ -z "$schema" ]; then

    if [ "$fallback" == "true" ]; then
        if [ -n "$local" ]; then
            schema=$(readlink -f $local)/_default.schema.json
        else
            schema=$(dirname $0)/_default.schema.json
        fi
    elif [ -f "$fallback" ]; then
        schema=$fallback
    else
        echo -e "${Red}Fallback schema $fallback not found${None}" >&2
        exit 1
    fi

    # log
    echo -e "${Yellow}Using fallback schema ${UYellow}$schema${None}" >&2
fi

# Check if schema is readable
if test -z "$schema"; then
    echo -e "${Red}Schema is missing${None}" >&2
    exit 1
fi

# Strip comments from JSON and go through normalization
# if parse "$json" "$schema" >/dev/null; then ## Uncomment this line to enable debug output
if validate "$json" "$schema"; then
    echo -e "${Green}JSON is valid and normalized${None}" >&2
else
    echo -e "${Red}JSON is empty or invalid${None}" >&2
    exit 1
fi | traverse $json >/tmp/$$.json

if test -z "$save"; then
    jq -C --indent ${tabSize:-2} . /tmp/$$.json
else
    jq -M --indent ${tabSize:-4} . /tmp/$$.json >$json
fi

#rm -f /tmp/$$.json
