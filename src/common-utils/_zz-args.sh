#!/bin/sh

typeset var count="0"
typeset var value=""
typeset var argname=""
typeset var varname=""
typeset var varnames=""
typeset var argnames=""
typeset var datatype=""
typeset var help=""
typeset var invert=""

##### VERIF #####
test $# -lt 1 && return 1

##### TITLE #####
typeset title=$1 && shift

##### CALLER #####
typeset caller=$1 && shift

##### READ, BUT NOT FROM KEYBOARD #####
while read argname datatype varname help; do
    if [ "$datatype" = "-" ]; then
        typeset name=""
    else
        typeset name="<$datatype>"
    fi

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

    varnames="$varnames\n$argname\t$varname"
    lineinfo="$lineinfo $line"

    [ "$argname" = "+" ] && break
done

##### LOOKUP ARGUMENTS #####
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

##### HELP #####
if [ "$OPTARG" = "h" ] || [ "$OPTARG" = "help" ]; then

    (
        echo -e ""
        echo -e "$title"
        echo -e ""
        echo -e "Usage: type \""$(basename $caller | tr '_' ' ')"$lineinfo -h\" for more info"
        echo -e "$helpinfo"
    ) >&2

    exit 1

elif [ "$OPTARG" = "@" ]; then
    echo "Special Argument!" >&2
else
    ##### REMOVE ARGUMENTS #####
    shift $(expr "$OPTIND" - 1)

    ##### REMAINING '-' PARAMETERS #####
    echo $varnames | grep -E "^-" | while read argname varname; do
        if [ "$#" -gt "0" ]; then
            export "$varname=$1" && shift 1
        fi
    done

    ###### REMAINING '+' PARAMETERS #####
    echo $varnames | grep -E "^\+" | while read argname varname; do
        if [ "$#" -gt "0" ]; then
            export "$varname=$(echo $@ | sed "s/ /\\\\ /g")" && shift $#

        fi
    done
fi
