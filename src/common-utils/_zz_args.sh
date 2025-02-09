#!/bin/sh

# Initialize variables
typeset var count="0"
typeset var value=""
typeset var argname=""
typeset var varname=""
typeset var varnames=""
typeset var argnames=""
typeset var datatype=""
typeset var help=""
typeset var invert=""

# Check if there are any arguments passed
test $# -lt 1 && return 1

# Set the title from the first argument
typeset title=$1 && shift

# Set the caller from the second argument
typeset caller=$1 && shift

# Read argument definitions from standard input
while read argname datatype varname help; do

    # Check if the argument requires a value
    if [ "$datatype" = "-" ]; then
        typeset name=""
    else
        typeset name="<$datatype>"
    fi

    # Check if the argument is optional
    if [ "$argname" = "-" ] || [ "$argname" = "+" ]; then
        typeset line="<$datatype>"
        helpinfo="$helpinfo\n\t$(printf '%-12s : %s' "$name" "$help")"
    else
        if [ "$datatype" = "-" ]; then
            typeset line="[-$argname]"
            argnames="$argnames$argname"
        else
            typeset line="[-$argname <$datatype>]"
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
    typeset var naming=$(echo -e "$varnames" | grep -E "^$value" | cut -f2)

    if [ -n "$OPTARG" ]; then
        export "$naming=$OPTARG"
    else
        export "$naming=-$value"
    fi
done

# Display help information if requested
if [ "$OPTARG" = "h" ] || [ "$OPTARG" = "help" ]; then

    (
        echo -e ""
        echo -e "$title"
        echo -e ""
        echo -e "Usage: $(basename $caller)$lineinfo; use -h for more information."
        echo -e "$helpinfo"
    ) >&2

    exit 1

elif [ "$OPTARG" = "@" ]; then
    echo "Stop processing arguments !" >&2
else
    # Shift the processed arguments
    shift $(expr "$OPTIND" - 1)

    # Process remaining '-' parameters
    for arg in $(echo -e $varnames | grep -E "^-" | cut -f2); do
        if [ "$#" -gt "0" ]; then
            export "$arg=$1" && shift 1
        fi
    done

    # Process remaining '+' parameters
    for arg in $(echo -e $varnames | grep -E "^\+" | cut -f2); do
        if [ "$#" -gt "0" ]; then
            export "$arg=$(echo $@ | sed "s/ /\\\\ /g")" && shift $#
        fi
    done

fi
