#!/bin/bash
set -e
bash -n "$0"
set +e
ls -d rubygem-* | \
  xargs -i bash -c "cd '{}' && set -x && for x in \$(spectool -A *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE '^(binstub|macros\.vagrant|macros|rubygems\.)' | grep -vE '(\.rb)$') ; do echo \"SHA512 (\$x) = \$(sha512sum \"\$x\" | cut -d' ' -f1)\" ; done > sources && fedpkg commit -c && git remote add pvalena 'ssh://pvalena@pkgs.fedoraproject.org/forks/pvalena/rpms/{}' && { gitc rebase || gitc -b rebase } && gitf pvalena && gitu -uf pvalena rebase || exit 255 ; gits ; gith"
