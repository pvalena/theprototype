#!/bin/bash
set -e
bash -n "$0"
set +e

grep -r '^%global bootstrap 1$' -l \
  | cut -d'/' -f1 \
  | sort -u \
  | xargs -i bash -c "cd '{}' || exit 255 ; set -x ; sed -i '/^%global bootstrap 1$/ d' *.spec ; rpmdev-bumpspec -c 'Enable tests.' -u 'Pavel Valena <pvalena@redhat.com>' *.spec ; fedpkg --release master commit -c ; gitu ; rm .built||: ; gith | colordiff"
