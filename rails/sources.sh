#!/bin/bash
set -e
bash -n "$0"
set +e
ls -d * | \
  xargs -i bash -c "cd '{}' || exit 255 ; set -x ; for x in \$(spectool -A *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE '^(binstub|macros\.vagrant|macros|rubygems\.)' | grep -vE '(\.rb)$') ; do echo \"SHA512 (\$x) = \$(sha512sum \"\$x\" | cut -d' ' -f1)\" ; done > sources ; gitd"
