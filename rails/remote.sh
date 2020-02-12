#!/bin/bash
set -e
bash -n "$0"
set +e

ls -d rubygem-*/ | \
  xargs -i bash -c "set -x ; cd '{}' || exit 255 ; git remote add pvalena 'ssh://pvalena@pkgs.fedoraproject.org/forks/pvalena/rpms/{}' ; gitc -b rebase || gitc rebase ; R=\$? ; [[ \$R -eq 0 ]] && gitf pvalena && gitu -uf pvalena rebase || exit 255"
