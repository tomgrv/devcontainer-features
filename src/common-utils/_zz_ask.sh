#!/bin/sh

# Source colors script
. zz_colors

# options are the first argument
default=$(echo "$1" | grep -oP '[A-Z]' | tr '[:upper:]' '[:lower:]')
options=$1
shift

echo "${BBlue}#${End} $* ${BBlue}[${options}]${End}"

# Loop while the input is not in the options
while true; do

  read -r confirm

  if [ -z "$confirm" ]; then
    echo $default
    break
  fi

  if echo "$options" | grep -q -i "$confirm"; then
    echo "$confirm"
    break
  fi

  zz_log w "Please enter a valid option from [${options}] (default: ${default}):"
done | grep -q -i "$default" 