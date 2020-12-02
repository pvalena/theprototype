#!/bin/bash

set -e
bash -n "$0"

myd="`dirname "$(readlink -e "$0")"`"
com="${myd}/get_pr_common.sh"

[[ -r "$com" ]] || false 'Could not find common!'
 . "$com"

yield '
    echo "$id"
  '
:
