#!/bin/bash
# Compare Rails core packages's versions using gem-compare
# TODO: DOC

 die () {
  echo "Error: $1!" 1>&2
  exit 1

 }

 FROM="5.0.0"
 INTO="5.0.0.1"

 mkdir tmp
 cd tmp || die "Could not cd to tmp"

 pwd
 ls

 bask "Remove all" && {
  rm -vfr *

 } || {
  bask "Continue" || exit 1

 }

 echo ">" ; while read x; do
        echo " >> $x"
        gem compare -bk "$x" "$FROM" "$INTO"
        echo

 done < <(tr -s ' ' <<< "activesupport
      activemodel
      activerecord
      actionview
      actionpack
      actionmailer
      actioncable
      railties
      rails" | cut -d' ' -f2 | grep -vE "^$") ; echo "<"
