#!/bin/bash
# Compare Rails core packages's versions using gem-compare
# TODO: DOC

 die () {
  echo "Error: $1!" 1>&2
  exit 1

 }

 [[ "$1" ]] && FROM="$1" || FROM="5.0.1"
 [[ "$2" ]] && INTO="$2" || INTO="5.0.2"

 mkdir -p tmp
 cd tmp || die "Could not cd to tmp"

 pwd
 ls

 echo -n "Remove all? "
 read R

 [[ "$R" == "y" || "$R" == "Y" ]] && rm -vfr *

 while read x; do
        echo " >> $x"
        gem compare -bk "$x" "$FROM" "$INTO" | lss
        echo

 done < <(tr -s ' ' <<< "activesupport
      activemodel
      activerecord
      actionview
      actionpack
      actionmailer
      actioncable
      activestorage
      activejob
      railties
      rails" | cut -d' ' -f2 | grep -vE "^$")
