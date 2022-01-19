#!/bin/bash
#
# ./test_ruby.sh [-c NUM|TASK]
#   Prototype for testing ruby and rubygems.
#   Runs rebuilds and collects results.
#
# Options
# =======
# (either)
#   TASK    number of koji task with built ruby to test against
#
# (or)
#   -c      continue with specific command (step)
#     NUM   number of step
#
#
# Issues
# ======
#   - Step 12 seems to produce invalid results.
#   - Requires pre-cloned packages' git in `$pkgsd`.
#   - Requires pre-configured mock - site-defaults.cfg (noclean=1 etc.)
#

set -xe
pkgsd="/home/pvalena/Work/RH/fedora/packages"
myd="`pwd`"
rpmq='provides requires recommends suggests enhances conflicts'

bask () {
  read -p "$1 " -n1 a
  echo

        [[ "$a" == "y" || "$a" == "yes" ]] || return 1
        return 0
}

runcmd () {
  find . -maxdepth 1 -mindepth 1 -type d -name 'rubygem-*' \
    | cut -d'/' -f2 \
    | sort -R \
    | xargs -i bash -c "echo ; set -x ; cd \"{}\" || exit 255 ; pwd ; $1 || exit 255"
  r=$?

  [[ -n "$2" ]] && sleep 0.5
  return $r
}

cleandir () {
  cd "$myd"
  ls *.noarch.rpm *.x86_64.rpm >/dev/null

  mock --clean -q
  sleep 0.1
  mock --init -q
  sleep 0.1
  mock -q -n -i *.noarch.rpm *.x86_64.rpm
  sleep 0.1
}

ggs () {
  echo "git status | grep -q \"$@\""
}

l=1

[[ -n "$1" ]] || exit 1
[[ -d "$pkgsd" ]] || exit 1

[[ "$1" == "-c" ]] && {
  shift
  [[ "$1" ]] && l=$1 || :
} || {
  bask "DW task '$1'?"

  cd "$myd"
  koji download-task $1 --arch x86_64 --arch noarch
  sleep 0.1

  cleandir
}

while :; do
  echo
  cd "$pkgsd"

  w=
  case $l in
    1) c="git status" ;;
    2) c="rm -rf result/ *.src.rpm *.gem *.tgz *.xz *.gz" ;;
    3) c="bclean" ;;
    4) c="`ggs "On branch master"`" ;;
    5) c="`ggs "Your branch is up-to-date with 'origin/master'"`" ;;
    6) c="`ggs "nothing to commit, working tree clean"`" ;;
    7) c="git pull" ;;
    8) c="rpmdev-bumpspec *.spec" ;;
    9) c="ls result/*.rpm >/dev/null && exit ; mockall -c" ; w=y ;;
    *) break ;;
  esac

  bask "Ready?" || continue

  runcmd "$c" "$w" || continue
  let "l += 1"
done

[[ $l -gt 12 ]] || {
  while :; do
    [[ $l -gt 10 ]] || {
      cleandir

      cd "$pkgsd"
      ls rubygem-*/result/*.noarch.rpm rubygem-*/result/*.x86_64.rpm >/dev/null && {
        mock -q -n -i rubygem-*/result/*.noarch.rpm rubygem-*/result/*.x86_64.rpm
      }
      l=11
    }

    while :; do
      echo
      cd "$pkgsd"

      w=
      case $l in
        11) c="mockall -c" ; w=y ;;
        12) c="rm -f result/*.src.rpm ; { set +x ; } &>/dev/null ; ls result/*.rpm | sort | while read p; do echo -e \"\\n> \$p\" ; for a in $rpmq; do echo \"\$a:\" ; rpm -qp \"\$p\" --\$a ; done ; done 2>&1 | tee test_rpm_new.txt" ;;
        13) break ;;
         *) exit 1 ;;
      esac

      bask "Ready?" || continue

      runcmd "$c" "$w" || continue
      let "l += 1"
    done

    bask "Continue rebuilding?" || break
    l=10
  done

  l=13
}

[[ $l -gt 13 ]] || {
  mock --clean -q
  sleep 0.1
  mock --init -q
  sleep 0.1
}

while :; do
  echo
  cd "$pkgsd"

  w=
  case $l in
    13) c="ls result/*.rpm | while read p; do q=\"\$( rpm --qf \"%{NAME}\" -qp \"\$p\" )\" ; mock -q -n -i \$p ; sleep 0.1 ; done" ;;
    14) c="{ set +x ; } &>/dev/null ; ls result/*.rpm | sort | while read p; do q=\"\$( rpm --qf \"%{NAME}\" -qp \"\$p\" )\" ; echo -e \"\\n> \$p\" ; mock -n -q --chroot \"for a in $rpmq; do echo \\\"\\\$a:\\\" ; rpm -q \\\"\$q\\\" --\\\$a ; done\" ; sleep 0.1 ; done 2>&1 | tee test_rpm_old.txt" ;;
    15) c="ls test_rpm_{old,new}.txt && diff -dbBZrNU 0 test_rpm_{old,new}.txt | tee test_rpm.diff" ;;
    16) break ;;
     *) exit 1 ;;
  esac

  bask "Ready?" || continue

  runcmd "$c" "$w" || continue
  let "l += 1"
done

cd "$pkgsd"
find . -maxdepth 2 -mindepth 2 -name test_rpm.diff -empty -delete
