#!/bin/bash
set -e
bash -n "$0"
set +e

x=pvalena

ls -d rubygem-*/ | cut -d'/' -f1 | \
  xargs -i bash -c "set -x ; cd '{}' || exit 255 ; git remote add $x ssh://$x@pkgs.fedoraproject.org/forks/$x/rpms/{}.git ; git fetch $x ; gitc rebase || gitcb rebase ; R=\$? ; [[ \$R -eq 0 ]] && gitb -u pvalena/rebase || exit 255"
