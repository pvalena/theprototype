#!/bin/bash
set -e
bash -n "$0"
set +e

x=copr-dist
y='pvalena/ruby-on-rails'

ls -d rubygem-*/ | cut -d'/' -f1 | \
  xargs -i bash -c "set -x ; cd '{}' || exit 255 ; git remote add $x https://copr-dist-git.fedorainfracloud.org/cgit/$y/{}.git ; git fetch $x ; gitc $x || gitcb $x ; R=\$? ; [[ \$R -eq 0 ]] && gitb -u $x/master || exit 255"
