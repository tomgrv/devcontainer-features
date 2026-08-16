#!/usr/bin/env bash

# _zz_input.sh
# Utility for handling parameter, file, or stdin input 
# Usage: zz_param [input] [description]

input="$1"

if [ -n "$input" ]; then
    if [ -f "$input" ]; then
        zz_log - "Reading from file: $input"
        cat $input
    else
        echo "$input"
    fi
else
    cat -
fi
