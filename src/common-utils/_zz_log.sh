#!/bin/sh

# Source colors script
. zz_colors

lvl="$1" && shift

case $lvl in
    i*)
        picto="{BBlue →} "
        base="White"
        ;;
    w*)
        picto="{BYellow !} "
        base="Yellow"
        ;;
    e*)
        picto="{BRed ✕} "
        base="Red"
        ;;
    s*)
        picto="{Green ✔} "
        base="Green"
        ;;
    -)
        picto="  "
        base="White"
        ;;
    *)
        picto="$lvl "
        base="White"
        ;;
esac

eval "$(
    echo "echo \"$picto$@\${End}\"" | sed -E "s/\{([A-Z]) /{\1${base} /g;s/\{([a-zA-Z]+) ([^}]*)\}/\${\1}\2\${${base}}/g;s/\\\\/\\\\\\\\/g;s/\r//g; "
)" >&2
