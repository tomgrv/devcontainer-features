#!/bin/bash

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Normalize JSON according to schema" $0 "$@" <<-help
        s -         save	    save normalized json to original file
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
    jq --arg path "$path" -e 'getpath($path | split(".") | map(select(length > 0)| gsub("^\"|\"$";"")))' 2>/dev/null >/dev/null

}

# Function to check if JSON is an array
is_true() {
    local path=${1:-.}
    get_path "$path" -r | jq -e 'if . == true then . else null end' >/dev/null
}

# Function to get the type of JSON element
get_json_type() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'type | tojson'
}

# Function to get JSON as string
get_json() {
    local path=${1:-.}
    get_path "$path" -r | jq -r 'tojson'
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
    get_path "$path" -r | jq -r 'keys_unsorted' | sed -e 's/^\[$//g' -e 's/^\]$//g' -e 's/,$//g' | sed -e 's/^[[:blank:]]*//g' -e '/^$/d'
}

# Function to get value at a given path
get_path() {
    local path=${1:-.}
    local raw=$(test -z "$2" && echo "-r" || echo "")

    jq --arg path "$path" $raw '
        def split_path:
            gsub("\\["; ".") | gsub("\\]"; "") | split(".") | map(
                select(length > 0) | gsub("^\"|\"$";"") | if test("^[0-9]+$") then tonumber else . end
            );
        getpath($path | split_path)'
}

# Function to resolve value at a given path
traverse() {
    local path=$1
    local prop=$2

    echo -n "$prop : "
    get_json "$path.$prop"
}

# Function to get remove comments from JSON.
# Do not remove comments inside strings.
load_json() {
    local file=${1:--}
    sed -re 's#^(([^"\n]*"[^"\n]*")*[^"\n]*)\/\/.*$#\1#' $file
}

load_json_schema() {
    local source=${1:--}
    local file=${2:-$source}

    load_json $file | jq --arg source "$source" 'if $source != "" and has("$id") then . else . + {"$id": $source} end'
}

oneOf_rule() {
    local size=$1
    local count=$2
    local index=$3

    test $count -eq 1
}

allOf_rule() {
    local size=$1
    local count=$2
    local index=$3

    test $count -eq $index
}

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
    curl -s $catalog | jq -r ".schemas[] | select(.name == \"$name\") | .url"
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

# Function to parse and validate JSON according to schema
parse() {

    ###!!! RETURN VALUE IS THE NUMBER OF VALIDATED ENTRIES

    # Arguments
    local json=$1       # JSON to validate (mandatory)
    local schema=$2     # Schema to use (mandatory)
    local path=$3       # Path to schema (optional)
    local real=$4       # Real path in JSON (optional)
    local call=${5:-$3} # Reference flag (optional)
    local not=$6        # Not flag (optional)
    local lvl=$7        # Recursive level for logs (optional)

    # if json is a file, load it
    if test -f "$json"; then
        echo -e "${lvl}${Green}Loading json ${UGreen}$json${None}" >&2
        json=$(load_json $json)
    fi

    # if schema is a file, load it
    if test -f "$schema"; then
        echo -e "${lvl}${Green}Loading schema ${UGreen}$schema${None}" >&2
        schema=$(load_json_schema $schema)
    fi

    # Local Variables
    local entry=""
    local found="0"
    local props=""
    local more=""
    local id=$(get_path ".\$id" <<<"$schema")

    # Log
    echo -e "${lvl}${Blue}Parsing schema <${path:-.}> == <${real:-.}>${None}" >&2

    # get 1st level entry points (oneOf, allOf, anyOf, properties) and loop through them
    for entry in $(get_keys "$path" <<<"$schema" | sort) '"$traverse"'; do

        echo -e "${lvl}- Processing <${Blue}${path}.$entry${None}>" >&2

        case $entry in

        \"oneOf\" | \"allOf\" | \"anyOf\")

            if is_json_array "$path.$entry" <<<"$schema"; then

                # Loop through array
                local size=$(get_array_size "$path.$entry" <<<"$schema")
                local last=$(expr $size - 1)
                local count=0

                echo -e "${lvl}- ${Cyan}Start $entry loop${None}" >&2

                for i in $(seq 0 $last); do
                    parse "$json" "$schema" "$path.$entry[$i]" "$real" "$path.$entry[$i]" "$not" "$lvl  | "
                    count=$(expr $count + $(expr $? \> 0))
                    ${entry//\"/}_rule $size $count $i && break
                done

                echo -e "${lvl}- ${Cyan}End $entry loop ($count/$size)${None}" >&2
                ${entry//\"/}_rule $size $count $last
                found=$(expr $found + $count)

            else
                echo -e "${lvl}- ${Red}Invalid $entry schema${None}" >&2
                exit 1
            fi
            ;;

        \"required\")

            local count=0
            local size=0

            for prop in $(get_array_items "$path.$entry" <<<"$schema"); do

                size=$(expr $size + 1)

                if is_existing_path "$real.$prop" <<<"$json"; then
                    if test -n "$not"; then
                        echo -e "${lvl}- ${Yellow}Property $prop is present but not required${None}" >&2
                        return 0
                    else
                        echo -e "${lvl}- ${Green}Property $prop is present${None}" >&2
                        count=$(expr $count + 1)
                    fi
                else
                    if test -z "$not"; then
                        echo -e "${lvl}- ${Yellow}Property $prop is missing but required${None}" >&2
                        return 0
                    else
                        echo -e "${lvl}- ${Green}Property $prop is absent${None}" >&2
                        count=$(expr $count + 1)
                    fi
                fi
            done

            # Check if all required properties are present
            found=$(expr $found + $(expr $count == $size))
            ;;

        \"not\")
            echo -e "${lvl}- ${Purple}Start Not${None}" >&2

            # Parse sub schema with not flag
            parse "$json" "$schema" "$path.$entry" "$real" "$path.$entry" "!" "$lvl  | "
            found=$(expr $found + $(expr $? \> 0))

            echo -e "${lvl}- ${Purple}End Not${None}" >&2
            ;;
        \"additionalProperties\")

            echo -e "${lvl}- Processing ${BWhite}Additional properties${None}" >&2

            if is_true "$path.$entry" <<<"$schema"; then

                echo -e "${lvl}- ${Purple}Additional properties allowed${None}" >&2

                for prop in $(get_keys "$real" <<<"$json" | sort); do
                    if ! grep -q $prop <<<"$props"; then
                        echo -e "${lvl}- Adding additional property <${Purple}$prop${None}>" >&2
                        more="$more $prop"
                    fi
                done
            fi
            ;;

        \"properties\")

            # Log
            echo -e "${lvl}- Processing ${BWhite}Properties${None}" >&2

            # if current path is an object, get properties
            if is_json_object "$real" <<<"$json"; then

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
                        parse "$json" "$schema" "$path.$entry.$prop" "$real.$prop" "$path.$entry.$prop" "$not" "$lvl  | "
                        found=$(expr $found + $(expr $? \> 0))

                    else
                        # Log
                        echo -e "${lvl}- ${Yellow}Property $prop is missing${None}" >&2
                    fi
                done
            else
                echo -e "${lvl}- ${Red}Invalid object schema${None}" >&2
                exit 1
            fi

            ;;
        \"\$traverse\")

            if test -z "$props"; then
                break
            fi

            # Log
            echo -e "${lvl}- ${BWhite}Finalizing output${None}" >&2

            local comma=""
            echo -n "{"

            for prop in $props $more; do

                # Log
                #echo -e "${lvl}- Processing property ${Purple}$real.$prop${None}" >&2

                if $not is_existing_path $real.$prop <<<"$json" >/dev/null; then

                    # Types can be string, object, array
                    case $type_value in
                    \"object\")
                        echo -e "${lvl}- Processing object <${Green}$prop${None}> " >&2
                        echo -n $comma && traverse "$real" "$prop" <<<"$json"
                        ;;
                    \"string\")
                        echo -e "${lvl}- Processing string <${Green}$prop${None}> " >&2
                        echo -n $comma && traverse "$real" "$prop" <<<"$json"
                        ;;
                    \"boolean\")
                        echo -e "${lvl}- Processing boolean <${Green}$prop${None}> " >&2
                        echo -n $comma && traverse "$real" "$prop" <<<"$json"
                        ;;
                    \"number\")
                        echo -e "${lvl}- Processing boolean <${Green}$prop${None}> " >&2
                        echo -n $comma && traverse "$real" "$prop" <<<"$json"
                        ;;
                    \"array\")
                        echo -e "${lvl}- Processing array <$prop> " >&2
                        local items_def=$(get_json "$path.$entry.$prop.items.type" <<<"$schema")
                        case $items_def in
                        \"string\")
                            echo -e "${lvl}  | Processing string items <${Green}$prop${None}> " >&2
                            echo -n $comma && traverse "$real" "$prop" <<<"$json"
                            ;;
                        \"object\")
                            echo -e "${lvl}  | Processing object items <$prop> " >&2
                            parse "$json" "$schema" "$path.$entry.$prop" "$real.$prop" "$path.$entry.$prop" "$not"
                            ;;
                        *)
                            echo -e "${lvl}  | ${Purple}Processing object items <$prop>${None}" >&2
                            echo -n $comma && traverse "$real" "$prop" <<<"$json"

                            ;;
                        esac
                        ;;
                    *)
                        echo -e "${lvl}- ${Purple}Processing items of $prop${None}" >&2
                        echo -n $comma && traverse "$real" "$prop" <<<"$json"
                        ;;
                    esac

                    # Add comma between properties
                    comma=","
                fi
            done
            echo -n "}"
            ;;

        \"type\")

            # Log
            echo -e "${lvl}- Processing ${BWhite}Type${None}" >&2

            local type_json=$(get_json_type "$real" <<<"$json")

            for type_schema in $(get_array_items "$path.$entry" <<<"$schema"); do

                local type_value=$(get_json_type "$real" <<<"$json")

                # Check if value type matches schema type and log only prop name
                if test "$type_value" != "$type_schema"; then
                    echo -e "${lvl}- ${Yellow}Property ${call##*.} is not of expected type ($type_value)${None}" >&2
                    continue
                fi

                # Log
                echo -e "${lvl}- Property ${Green}${call##*.}${None} is of expected type ($type_value)${None}" >&2

                #Flag to indicate that the property was found
                found=$(expr $found + 1)

                # Only one type is allowed
                break
            done
            ;;
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

            echo -e "${lvl}- Ref is ${Yellow}${ref}${None} from ${Yellow}${id}${None}..." >&2

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

            parse "$json" "$schema" "$(echo $fgt | tr '/' '.')" "$real" "$path" "$not" "$lvl  | "
            found=$(expr $found + $?)
            ;;
        *)
            # Log
            echo -e "${lvl}- Entry ${BWhite}$entry${None} not handled" >&2
            ;;
        esac
        # add { and} around output if not null using sed or awk
    done
    echo -e "${lvl}- ${Blue}$found${None} schema item valid" >&2
    return $found
}

# If schema is not provided, try to find it locally
if [ ! -f "$schema" ]; then

    #echo -e "${Yellow}Schema not provided!${None}"
    # Identify package type from file name just before json extension
    type=$(basename $json | sed -E 's/\.json$//' | sed -E 's/.*\.(.*)/\1/')

    # Identify schema file
    schema=$(dirname $0)/_$type.schema.json
    default=$(dirname $0)/_default.schema.json
fi

# Check if schema file exists, and if not, download it from schema store
if [ ! -f "$schema" ]; then

    echo -e "${Yellow}Schema $schema not found locally, downloading it from schema store${None}"

    # find schema file url from schema store catalog
    schema_url=$(get_schema_url $(basename $json))

    if [ -z "$schema_url" ]; then
        echo -e "${Yellow}Schema file not found in schema store catalog, using default schema${None}"
        type=default
        schema=$default
    else
        get_schema $schema_url >$(dirname $0)/_$type.schema.json
    fi
fi

# Check if schema is readable
if test -z "$schema" && test ! -f "$schema"; then
    echo -e "${Red}Schema is missing${None}"
    exit 1
fi

# Strip comments from JSON and go through normalization
# if parse "$json" "$schema" >/dev/null; then ## Uncomment this line to enable debug output
if parse $json $schema; then
    echo -e "${Red}JSON is empty of invalid${None}" >&2
    exit 1
else
    echo -e "${Green}JSON is valid and normalized${None}" >&2
    exit 0
fi | if test -z "$save"; then jq -C --indent ${tabSize:-2}; else jq -M --indent ${tabSize:-4} >$json.sorted; fi
