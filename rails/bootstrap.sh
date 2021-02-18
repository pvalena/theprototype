#!/bin/bash
set -e
bash -n "$0"
set +e

M='Enable tests.'

grep -r '^%bcond_without bootstrap$' -l \
  | cut -d'/' -f1 \
  | sort -u \
  | xargs -i bash -c "
    echo
    set -ex
    cd '{}'
    pwd
    sed -i 's/^%bcond_without bootstrap/%bcond_with bootstrap/' *.spec
    git commit -am '$M'
    rm .built
  "
