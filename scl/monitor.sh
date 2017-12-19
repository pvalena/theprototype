#!/bin/bash

 P=""
 while X="`~/Work/RH/my/scl/listpkgs.sh -k "$@"`" ; do
  [[ "$P" == "$X" ]] || {
    clear
    twocol -w 50 <<< "$X"
    P="$X"

  }

  sleep 3m

 done
