#!/bin/bash
set -e
bash -n "$0"
set +e
ls -d * | \
  xargs -i bash -c "cd '{}' || exit 255 ; set -x ; fedpkg commit -c ; gith"
