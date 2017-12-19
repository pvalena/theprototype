#!/bin/bash
#

ls | xargs -n1 -i bash -c "echo ; echo ; D=\"\$(readlink -e {})\" ; [[ -d \"\$D\" ]] || { echo \"BIGFAIL: '{}'\" ; exit 255 ; } ; set -x ; cd \"\$D\" || exit 255 ; { git f ; git c master ; } &>/dev/null ; git s | grep -q \"On branch master\" && { git p &>/dev/null ; git p | grep -q \"Already up-to-date.\" && fedpkg sources && exit 0 ; } ; { set +x ; } &>/dev/null ; echo 'FAIL: {}' ; git s"
