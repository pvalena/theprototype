#!/usr/bin/bash

target=rubygems

set -e
bash -n "$0"

xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:$target' --latest-limit=1"
fail="{ echo '{}' >> `readlink -f failed.txt`; exit 1; }"

while [[ -n "$1" ]]; do
  p="$1"
  shift ||:
  bash -c " set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -u | grep '^rubygem\-'" \
    | tee -a error.log \
    | xargs -i bash -c "[[ -d '{}' ]] || fedpkg co '{}'; cd '{}' || $fail; echo; pwd; gitc master; gitfo; giteo; gits; # echo ~/Work/lpcsn/home/lpcs/lpcsf-new/test/scripts/pkgs/cr-build.sh $target || $fail; sleep 10"
done
