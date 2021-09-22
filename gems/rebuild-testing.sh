#!/bin/zsh

set -xe
zsh -n "$0"

rebuild () {
  for x in `seq 1 "${1}"`; do
    echo ">> $x"
    grep -r "$2" -l | cut -d'.' -f1 | run
  done
}

run () {
  sort -uR \
    | grep '^rubygem-' \
    | tee -a error.log \
    | xargs -ri zsh -c "cd .. || exit 255; echo -e '\n> {}'; [[ -d '{}' ]] || fedpkg co '{}'; set -e; cd '{}'; gits; echo; gits | grep -q \"Your branch is behind 'pvalena/rebase' by 1 commit, and can be fast-forwarded.\" && ! gits | grep -q 'modified:' && ! gits | grep -q '^Changes not staged for commit' && gite pvalena/rebase ; ~/Work/lpcsn/home/lpcs/lpcsf-new/test/scripts/pkgs/cr-build.sh $target ; sleep 16"
}

{ set +ex ; } &>/dev/null
set -o pipefail

target="${1:-rubygems}"
shift

N="${1:-1}"
shift

grep -E '^[0-9]+' <<< "$N" || exit 1

cd "copr-r8-$target" || exit 1

for n in {1..$N}; do
  echo -e "\n>>> Build missing packages (1x)"
  grep -r 'requires libruby.so.2.7()(64bit)' \
    | cut -d' ' -f4 | sort -u \
    | xargs -r dnf repoquery whatrequires --disablerepo='*' --enablerepo='rawhide' --enablerepo='copr:copr.fedorainfracloud.org:pvalena:$target' --qf '%{source_name}' \
    | run

  B=(
   3 'cannot install both ruby-libs-'
   1 'RPM build errors'
  )
  for BT BF in ${B}; do
    echo -e "\n>>> $BF (${BT}x)"
    [[ -z "$BT" ]] && exit 1
    [[ -z "$BF" ]] && exit 2

    rebuild "$BT" "$BF"
  done
done
