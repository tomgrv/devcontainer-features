#!/bin/bash

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Validate JSON according to schema" $0 "$@" <<-help
        a -         allow	    allow additional properties at root level
        d -         debug	    debug output
        c -         cache	    allow caching
        f fallback  fallback	fallback schema to use if none found locally
        l local     local	    infer schema in <local> folder from json file name (x.y.json => <local>/y.schema.json). Use "true" to use script folder
        i -         import	    infer on schema store if nothing found locally (x.y.json => "y" on schema store)
        s schema	schema		schema to use to validate json
        - json	    json		json to validate
help
)

# Function to check if input is valid JSON
is_json() {
    jq empty 2>/dev/null
}

# Function to check if JSON is an array
is_json_array() {
    local path=${1:-.}
    get_path "$path" -r | jq -e 'if type == "array" then . else null end' >/dev/null
}

# Function to check if JSON is an object
is_json_object() {
    local path=${1:-.}
    get_path "$path" -r | jq -e 'if type == "object" then . else null end' >/dev/null
}

# Function to check if JSON contains a $ref
is_json_ref() {
    local path=${1:-.}
    get_path "$path" -r | jq -e 'if type == "object" and has("$ref") then . else null end' >/dev/null
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
        getpath($path | split_path)' 2>/dev/null
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

    # if json is a file, load it
    if test -f "$json" || test -n "$(echo $json | grep -E '^http')"; then
        json=$(zz_json $json)
    fi

    # if json is not a valid JSON, return error
    if ! is_json <<<"$json"; then
        zz_log e "Invalid json" && exit 1
    fi

    # load schema
    if test -f "$schema" || test -n "$(echo $schema | grep -E '^http')"; then
        zz_log "${lvl} -" "Loading ${Yellow}${uri}${None}..."
        schema=$(zz_json -s $schema)
    fi

    # if schema is not a valid JSON, return error
    if ! is_json <<<"$schema"; then
        zz_log e "Invalid schema" && exit 1
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
            lvl="$lvl   |"
        done
    fi

    # Log
    zz_log "${lvl}" "{Blue Parsing schema <${path:-.}> == <${real:-.}>} {None at level <$level>}"

    # get 1st level entry points (oneOf, allOf, anyOf, properties) and loop through them
    for entry in '"$id"' '"not"' '"oneOf"' '"allOf"' '"anyOf"' '"type"' '"required"' '"$ref"' '"properties"' '"items"' '"additionalProperties"'; do

        # Use entry if it exists in schema
        if ! is_existing_path "$path.$entry" <<<"$schema"; then
            continue
        fi

        zz_log "${lvl} -" "Processing <{Blue ${path}:$entry}>"

        case $entry in

        \"\$id\")

            #log
            zz_log "${lvl} -" "Processing {B Id}"

            # get id from schema
            id=$(get_json "$path.$entry" <<<"$schema" || echo ".")

            # log
            zz_log "${lvl} -" "Resolving ${Yellow}$id"
            ;;

        \"\$ref\")

            # get ref from schema by using $id as base path if it exists and ref is a local reference
            local ref=$(get_path "$path.$entry" <<<"$schema")

            if test "$ref" == "null" || test -z "$ref"; then
                zz_log e "Reference not found for $path.$entry" && exit 1
            fi

            zz_log "${lvl} -" "Ref is {Yellow ${ref}}"
            zz_log "${lvl}  " "From {Yellow ${id}}..."

            # separate uri before # from fragment after #
            local uri=$(echo $ref | awk -F '#' '{print $1}')
            local fgt=$(echo $ref | awk -F '#' '{print $2}')

            if test -n "$uri"; then
                # check if file exists
                if test -f "$uri" || test -n "$(echo $uri | grep -E '^http')"; then
                    zz_log "${lvl} -" "Loading ${Yellow}${uri}${None}..."
                    schema=$(zz_json -s $uri)
                elif test -n "$id"; then
                    # load schema from file
                    zz_log "${lvl} -" "Loading ${Yellow}$(dirname $id)/$uri${None}..."
                    schema=$(zz_json -s $(dirname $id)/$uri)
                else
                    zz_log e "Unable to resolve reference {U $ref} using {B $id}" && exit 1
                fi
            fi

            if ! is_json <<<"$schema"; then
                zz_log e "Unable to load reference {U $uri}" && exit 1
            fi

            # if schema is not a valid JSON, return error
            if ! validate "$json" "$schema" "$(echo $fgt | tr '/' '.')" "$real" "$path" "$not" "$level"; then
                zz_log "${lvl} -" "{Yellow Reference $ref is invalid}"
                return 1
            fi
            ;;

        \"not\")
            zz_log "${lvl} -" "{Purple Start Not}"

            # Parse sub schema with not flag
            if ! validate "$json" "$schema" "$path.$entry" "$real" "$path.$entry" "!" "$level"; then
                zz_log "${lvl} -" "{Yellow Condition is invalid}"
                return 1
            fi

            zz_log "${lvl} -" "{Purple End Not}"
            ;;

        \"oneOf\" | \"allOf\" | \"anyOf\")

            if ! is_json_array "$path.$entry" <<<"$schema"; then
                zz_log e "Invalid $entry schema" && exit 1
            fi

            # Loop through array
            local size=$(get_array_size "$path.$entry" <<<"$schema")
            local last=$(expr $size - 1)
            local count=0

            zz_log "${lvl} -" "{Cyan Start $entry loop}"

            for i in $(seq 0 $last); do
                if validate "$json" "$schema" "$path.$entry[$i]" "$real" "$path.$entry[$i]" "$not" "$level"; then
                    count=$(expr $count + 1)
                fi
                ${entry//\"/}_rule $size $count $i && break
            done

            zz_log "${lvl} -" "{Cyan End $entry loop ($count/$size)}"
            ${entry//\"/}_rule $size $count $last || return 1
            ;;

        \"type\")

            # Log
            zz_log "${lvl} -" "Processing {B Type}"

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
                zz_log "${lvl} -" "${Yellow}Property ${real:-.} is ${type_json}, not of expected type ${type_schema}"
                return 1
            fi

            echo ${real:-.}

            # Log
            zz_log "${lvl} -" "${Green}Property ${real:-.} is of expected type ${type}"
            ;;

        \"required\")

            local count=0
            local size=0

            # if type is not an object, do not process
            if test "$type" != "\"object\""; then
                zz_log "${lvl} -" "${Yellow}Skip required not an object ($type)"
                continue
            fi

            # loop through required properties
            for prop in $(get_array_items "$path.$entry" <<<"$schema"); do

                size=$(expr $size + 1)

                if is_existing_path "$real.$prop" <<<"$json"; then
                    if test -n "$not"; then
                        zz_log "${lvl} -" "${Yellow}Property $prop is present but not required"
                        return 1
                    fi
                else
                    if test -z "$not"; then
                        zz_log "${lvl} -" "${Yellow}Property $prop is missing but required"
                        return 1
                    fi
                fi

                zz_log "${lvl} -" "${Green}Property requirement is valid for $prop"
            done
            ;;

        \"items\")

            # If items is not an array, do not process
            if test "$type" != "\"array\""; then
                zz_log "${lvl} -" "${Yellow}Skip properties not an  ($type)"
                continue
            fi

            # Log
            zz_log "${lvl} -" "Processing ${BWhite}Items"

            # get items schema
            items=$(get_path "$path.$entry" <<<"$schema")

            # Loop through items
            for item in $(get_keys "$real" <<<"$json" | sort); do

                # Log
                zz_log "${lvl} -" "Processing item ${Purple}$item"

                if ! validate "$json" "$schema" "$path.$entry" "$real.$item" "$path.$entry" "$not" "$level"; then
                    zz_log "${lvl} -" "${Orange}Item $item is invalid"
                    return 1
                fi
            done
            ;;

        \"properties\")

            # If items is not an object, do not process
            if test "$type" != "\"object\""; then
                zz_log "${lvl} -" "${Yellow}Skip properties not an object ($type)"
                continue
            fi

            # Log
            zz_log "${lvl} -" "Processing ${BWhite}Properties"

            # get properties list
            props=$(get_keys "$path.$entry" <<<"$schema" | tr "\n" " ")

            # Log
            #echo  "${lvl}- Properties are ${Purple}$props"

            # Loop through properties
            for prop in $props; do

                #echo  "${lvl}- Processing property ${Purple}$prop"
                if $not is_existing_path "$real.$prop" <<<"$json"; then

                    # Log
                    zz_log "${lvl} -" "Processing <${Purple}$prop${None}>"

                    # Parse sub schema
                    if ! validate "$json" "$schema" "$path.$entry.$prop" "$real.$prop" "$path.$entry.$prop" "$not" "$level"; then
                        zz_log e "Property $prop is present but invalid${Red}" >&2
                        return 1
                    fi
                else
                    # Log
                    zz_log "${lvl} -" "${Yellow}Skip property $real.$prop not present"
                fi
            done

            #echo "${real:-.}"
            ;;

        \"additionalProperties\")

            zz_log "${lvl} -" "Processing ${BWhite}Additional properties"
            if is_existing_path "$path.$entry" <<<"$schema"; then

                zz_log "${lvl} -" "${Purple}Additional properties allowed for ${real:-.}"

                for prop in $(get_keys "$real" <<<"$json" | sort); do

                    if ! grep -q -x "$prop" <<<"$props"; then
                        zz_log "${lvl} -" "Adding additional property <${Purple}$real.$prop${None}>"

                        # Keep track of validated path
                        echo "$real.$prop"
                    fi
                done
            fi
            ;;
        esac
    done

    # Log
    zz_log "${lvl}" "{Blue End Parsing, all valid!}" >&2
}

# if local flag is set, get schema from json file name
if [ -n "$local" ] && [ -z "$schema" ]; then

    # Identify package type from file name just before json extension
    type=$(basename -s .json $json | sed -E 's/.*\.(.*)/\1/')

    if [ "$local" == "true" ]; then
        local=$(dirname $(readlink -f $0))
    fi

    # Check if schema file exists
    if [ -f "$local/_$type.schema.json" ]; then
        schema=$local/_$type.schema.json
    fi

    # log
    zz_log i "Infering schema from local folder {U $local} for {UYellow $json}"
fi

# Check if schema file exists, and if not and import allowed, download it from schema store
if [ -n "$import" ] && [ -z "$schema" ]; then

    search=$(basename -s .json $json | sed -E 's/.*\.(.*)/\1/').json

    # find schema file url from schema store catalog
    schema=$(get_schema_url $search)

    # log
    zz_log i "Infering schema from schema store for {UYellow $search} ${schema:+"found!"}"
fi

# if schema file does not exist, use fallback schema
if [ -n "$fallback" ] && [ -z "$schema" ]; then

    if [ "$fallback" == "local" ] && [ -n "$local" ]; then
        schema=$(readlink -f $local)/_default.schema.json
    elif [ -f "$fallback" ]; then
        schema=$fallback
    else
        zz_log e "Fallback schema $fallback not found" && exit 1
    fi

    # log
    zz_log w "Using fallback schema {UYellow $schema}"
fi

# Download schema file and add id to it if not present
schema=$(zz_json -s "$schema")

# Check if schema is readable
if test -z "$schema"; then
    zz_log e "Schema is missing" && exit 1
fi

# if schema is not a valid JSON, return error
if ! is_json <<<"$schema"; then
    zz_log e "Invalid schema" && exit 1
fi

# if allow flag is set, allow additional properties at root level
if test -n "$allow"; then
    zz_log w "Additional properties allowed at root level"
    schema=$(echo "$schema" | jq '. + {"additionalProperties": true}' -)
fi

# is cache flag is set, cache schema
hash=$(
    (
        jq 'paths | map(tostring) | join(".")' $json
        echo "$schema" | jq 'paths | map(tostring) | join(".")'
    ) | sort -u | md5sum | awk '{print $1}'
)
map=~/.cache/$hash.schema.map
zz_log i "Hash is {B $hash}"

if test -n "$cache" && test -s $map; then
    zz_log - "Using cached validation map"
    cat $map
else

    # Validate JSON according to schema and display valid json paths
    if validate "$json" "$schema"; then
        zz_log s "File {U $json} valid"
    else
        zz_log e "File {U $json} empty or invalid" && exit 1
    fi | sed -n -e 's/^.//g' -e '/^$/d' -e 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P'
fi
