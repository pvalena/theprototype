#!/usr/bin/bash

set -e
bash -n "$0"

target="${1:-rubygems}"
shift

xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:$target' --latest-limit=1"

fail="{ echo '{}' >> `readlink -f failed.txt`; exit 1; }"

set +e

while [[ -n "$1" ]]; do
  p="$1"
  shift ||:
  bash -c " set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -u | grep '^rubygem\-'" \
    | tee -a error.log \
    | xargs -i bash -c "[[ -d '{}' ]] || fedpkg co '{}'; cd '{}' || $fail; echo; pwd; gitc rawhide; gitfo; gitt; giteo; fedpkg sources; gits; ~/Work/lpcsn/home/lpcs/lpcsf-new/test/scripts/pkgs/cr-build.sh $target; sleep 10"
done
