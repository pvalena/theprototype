#!/usr/bin/bash

set -e
bash -n "$0"

xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:ruby-testing' --enablerepo='copr:copr.fedorainfracloud.org:pvalena:rubygems-testing' --latest-limit=1"
fail="{ echo '{}' >> `readlink -f failed.txt`; exit 1; }"

while [[ -n "$1" ]]; do
  p="$1"
  shift ||:
  bash -c " set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -u | grep '^rubygem\-'" \
    | tee -a /dev/stderr \
    | xargs -i bash -c "[[ -d '{}' ]] || fedpkg co '{}'; cd '{}' || $fail; echo; pwd; gitc master; gitfo; giteo; gits; ~/lpcsf-new/test/scripts/pkgs/cr-build.sh rubygems-testing || $fail; sleep 10"
done
