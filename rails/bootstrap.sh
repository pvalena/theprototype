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

    # Is the remote diff empty, a part from the above change?
    D=\"\$(git diff \"pvalena/\$gitb | grep '^* ' | cut -d' ' -f2-)\" | grep -vE '^(\+|\-)%bcond_with' | grep -v '^ ' | grep -v '^@@ ' | grep -v '^\-\-\- ' | grep -v '^index ' | grep -v '^diff ' | grep -v '^\+\+\+ ')\"
    [[ -z \"\${D}\" ]] && git push -f
  "

exit 0
