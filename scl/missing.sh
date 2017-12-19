#!/bin/bash

 [[ "$4" ]] && D="$4" || D="$3"

 P=""
 while Z="`~/Work/RH/my/scl/listpkgs.sh $2 $D | cut -d'-' -f2- | while read z; do echo -n "|$z" ; done`" ; do

  X="`~/Work/RH/my/scl/listpkgs.sh $1 $3 | grep -vE "^rubygem-(${Z:1})$"`" || break

  [[ "$P" == "$X" ]] || {
    clear
    twocol -w 50 <<< "$X"
    P="$X"

  }

  sleep 3m

 done
