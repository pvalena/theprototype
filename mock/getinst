#!/bin/bash
#

[[ "$1" ]] || { echo "Arg missing" >&2 ; exit 1 ; }

while [[ "$1" ]]; do
  [[ -r "$1" ]] || { echo "File '$1' is not readable" >&2 ; exit 1 ; }

  tr -s '\t' ' ' < "$1" | grep '^DEBUG util.py:' | sed -e 's/ is already installed, skipping.$//g' \
    | grep -E '\.(x86_64|noarch|i686)$' | rev | cut -d' ' -f1 | rev | grep -v '^/' | sort -u

  #grep ': Installed packages:' -A $H | grep -E '\.(x86_64|noarch|i686)$'
   #| grep ': Child return code was: ' -B $H \
    #| grep '^DEBUG util.py:' #| tail -n +2 | head -n -1 | cut -d' ' -f3- \
    #| sed 's/\.x86_64 / /g' | sed 's/\.i686 / /g' | sort -u

  shift

done
