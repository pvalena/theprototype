#!/bin/bash

  . lpcsbclass

 pth="$(readlink -e "`dirname "$0"`/t e s t.sh")"

 echo "$pth"

 [[ -x "$pth" ]] || die "'$pth' missing or not executable"

 sleep 3

 exec "$pth" -this -s -p "kdfjgn dfkgj ndkfjgn kdfjgn "
