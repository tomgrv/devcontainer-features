#!/bin/sh

# Source colors script
. zz_colors

# Initialize variables
count="0"
value=""
argname=""
varname=""
varnames=""
argnames=""
datatype=""
help=""
invert=""

# Display help information if no arguments are passed
if test $# -lt 1; then
    echo "Usage: $(basename $0) <title> <caller> <<-help
        ...
        <argname> <datatype> <varname> <help>
        ...
        help" >&2
    return 1
fi

# Set the title from the first argument
title=$1 && shift

# Set the caller from the second argument
caller=$1 && shift

# Read argument definitions from standard input
while read argname datatype varname help; do

    # Check if the argument requires a value
    if [ "$datatype" = "-" ]; then
        name=""
    else
        name="<$datatype>"
    fi

    # Check if the argument is optional
    if [ "$argname" = "-" ] || [ "$argname" = "+" ]; then
        line="<$datatype>"
        helpinfo="$helpinfo\n\t$(printf '%-12s : %s' "$name" "$help")"
    else
        if [ "$datatype" = "-" ]; then
            line="[-$argname]"
            argnames="$argnames$argname"
        else
            line="[-$argname <$datatype>]"
            argnames="$argnames$argname:"
        fi

        helpinfo="$helpinfo\n\t$(printf '%-3s %-8s : %s' "-$argname" "$name" "$help")"
    fi

    # Add the argument to the list of variables
    varnames="$varnames\n$argname\t$varname"
    lineinfo="$lineinfo $line"

    [ "$argname" = "+" ] && break
done

# Parse the command-line arguments
while getopts :$argnames value "$@"; do
    if [ "$value" = "?" ]; then
        break
    fi

    naming=$(echo "$varnames" | grep -E "^$value" | cut -f2)

    if [ -n "$OPTARG" ]; then
        echo "$naming=$OPTARG"
    else
        echo "$naming=-$value"
    fi
done

# Display help information if requested
if [ "$OPTARG" = "h" ] || [ "$OPTARG" = "help" ]; then

    (
        echo ""
        echo "$title"
        echo ""
        echo "Usage: ${Yellow}$(basename $caller)$lineinfo${None}; use ${Yellow}-h${None} for more information."
        echo "$helpinfo"
        echo ""
    ) >&2

    exit 1

elif [ "$OPTARG" = "@" ]; then
    echo "Stop processing arguments !" >&2
else
    # Shift the processed arguments
    shift $(expr "$OPTIND" - 1)

    # Process remaining '-' parameters
    for arg in $(echo $varnames | grep -E "^-" | cut -f2); do
        if [ "$#" -gt "0" ]; then
            echo "$arg=$1" && shift 1
        fi
    done

    # Process remaining '+' parameters
    for arg in $(echo $varnames | grep -E "^\+" | cut -f2); do
        if [ "$#" -gt "0" ]; then
            echo "$arg=$(echo $@ | sed "s/ /\\\\ /g")" && shift $#
        fi
    done

fi
