#!/bin/sh

# Source colors script
. zz_colors

lvl="$1" && shift

case $lvl in
i*)
    picto="→"
    base="Blue"
    ;;
w*)
    picto="!"
    base="Yellow"
    ;;
e*)
    picto="✕"
    base="Red"
    ;;
s*)
    picto="✔"
    base="Green"
    ;;
*)
    picto="$lvl"
    base="White"
    ;;
esac

eval "$(
    if [ -n "$picto" ]; then
        echo "echo \"{B $picto} $*\${End}\""
    else
        echo "echo \"$*\${End}\""
    fi | sed -E "s/\{([A-Z]) /{\1${base} /g;s/\{([a-zA-Z]+) ([^}]*)\}/\${\1}\2\${${base}}/g; s/\r//g; "
)" >&2
