#!/bin/bash

set -e
bash -n "$0"

### REPORTING START ###
{

## METHODS
section () {
  local l="###############################"
  { echo; } 2>/dev/null
  : "${l} $@ ${l}"
}

fail () {
  local mu=
  local se='```'
  local mg=
  [[ "$1" == "-s" ]] && {
    mg="needs inspection"
    shift
    :
  } || mg="failed"

  echo -n "**${mg}"

  [[ -z "$1" ]] || {
    [[ "`wc -l <<< "$1"`" == "1" ]] \
      && echo -n " (${1})" \
      || mu=y
  }

  echo "**"
  [[ -n "$mu" ]] && {
    echo -e "${se}\n"
    echo "${1}"
    echo -e "\n${se}"
  }
}

abort () {
  echo "--> Testing failed: " "$@" >&2
  exit 1
}

# mock changes it's verbosity if output is redirected
[[ -t 1 ]] && v='' || v="-v "
msr="${v}-n --isolation=nspawn --result=./result"
mar='--bootstrap-chroot'
mrr='fedora-rawhide-'
mrn=1
mrs='-x86_64'
mck () {
  a=""
  while [[ -n "$1" ]]; do a="$a '$1'"; shift; done

  bash -c "set -x ; mock $msr -r ${mrr}${mrn}${mrs} $mar $a"
  return $?
}

srpm () {
  {
    rm -rf result/
    rm *.src.rpm
  } &>/dev/null

  mck --buildsrpm --spec *.spec --sources . 2>&1 \
    || abort 'Failed build SRPM.'

  mv -f result/*.src.rpm . || abort "Failed to copy SRPM."
  ls *.src.rpm &>/dev/null || abort "Failed to locate SRPM."
}


## CONSTANTS
rel='34'

me="pvalena"
mc="rubygems"
gp='rubygem-'

COPR_URL="https://download.copr.fedorainfracloud.org/results/$me/"

tb='copr-dist'
rm="${tb}/rawhide"
bl='result/build.log'

MYD="`readlink -e "$(dirname "$0")/.."`"
[[ -d "$MYD" ]] || abort "Could not scripts directory"


## ARGS
[[ "$1" == '-b' ]] && {
  CR="$2"
  shift 2
  :
} || CR=

[[ "$1" == '-c' ]] && {
  CON="$1"
  shift
  :
} || CON=

[[ "$1" == '-f' ]] && {
  FAS="$1"
  shift
  :
} || FAS=

[[ "$1" == '-k' ]] && {
  KJ="$2"
  shift 2
  :
} || KJ=

[[ "$1" == '-n' ]] && {
  CINIT=
  shift
  :
} || CINIT="`echo --{clean,init}`"

[[ "$1" == '-p' ]] && {
  pr="$2"
  shift 2
  :
} || pr=

[[ "$1" == '-r' ]] && {
  mrr="$2"
  shift 2
  :
} || mrr="fedora-rubygems-"

[[ "$1" == '-u' ]] && {
  UPD="$1"
  shift
  :
} || UPD=

[[ "$1" == '-v' ]] && {
  mc="vagrant"
  gp="vagrant-"
  shift
  :
}


## INIT
[[ -n "$KJ$FAS" ]] || {
  kl="$me@FEDORAPROJECT\.ORG"
  klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' || {
    kinit "$kl" -l 30d -r 30d -A || abort "Failed to kinit: $kl"
    pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
  }
}

set +e
set -o pipefail

p="$1"
[[ -n "$p" ]] && {
  grep -q "^$gp" <<< "$p" || p="$gp$p"
  [[ -d "$p" ]] || {
    fedpkg --user "$me" clone -a "$p" || abort "Failed to clone: $p"
  }
  cd "$p" || abort "Failed to CD: $p"
  :
} || {
  p="`basename "$PWD"`" || abort "Invalid PWD: $PWD"
}
g="$(cut -d'-' -f2- <<< "$p")"

[[ -n "$p" && -n "$g" ]] || abort "Invalid Gem, package name: '$g', '$p'"
grep "^$gp" <<< "$p" &>/dev/null || abort "Invalid prefix in '$p', expected: $gp"


## Pull changes (non-continue)
[[ -n "$CON" ]] || {
  gitt || abort 'Failed to stash'

  # Use COPR repo as default
  [[ -n "$pr$CR" ]] || {
    #for x in {1..2}; do
    #  git remote remove "$tb"
    #done

    git remote add "${tb}" "https://copr-dist-git.fedorainfracloud.org/cgit/$me/$mc/$p.git"
    gitf "$tb" || abort "Failed to fetch: $tb"
    gitc "$tb" \
      || gitcb "$tb" -t "$rm"

    [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "$tb" ]] \
      || abort "Failed to checkout copr branch '$tb'"

    gitrh "$rm" || abort "Failed to reset to $rm"
    gitb -u "$rm" || abort "Failed set upstream to $rm"
  }

  # Specific Copr build
  [[ -z "$CR" ]] || {
    u="${COPR_URL}${mc}/fedora-rawhide-x86_64/`printf "%08d" $CR`-${p}/"
    srcf="$(
      curl -Lksf "$u" \
        | tr -s '<' '\n' \
        | grep -E "^a href='.*\.src\.rpm'" \
        | cut -d"'" -f2
    )"
    [[ -n "$srcf" ]] || abort "SRPM not found in: $u"

    rm *.src.rpm &>/dev/null
    curl -OLksf "$u/$srcf"
    [[ -r "$srcf" ]] || abort "SRPM download failed: $u/$srcf"

    rpm2cpio "$srcf" \
      | cpio -uidmv --no-absolute-filenames \
      || abort "Failed to unpack SRPM: $srcf"
  }

  # TODO: koji build?
  # git remote add "$me" "ssh://$me@pkgs.fedoraproject.org/forks/$me/rpms/$p"
  # gitf "$me"

  # Pull request from dist-git
  [[ -z "$pr" ]] || {
    gitc rawhide || abort 'Failed to checkout rawhide'
    gitb -D "pr$pr" || abort "Failed to delete branch pr$pr"
    git fetch origin "refs/pull/$pr/head:pr$pr" || abort "Failed to fetch: origin 'refs/pull/$pr/head:pr$pr'"
    gitc "pr$pr"

    [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "pr$pr" ]] \
      || abort "Failed to checkout the PR #$PR"
  }

  # Simply fetch latest gem
  # rm *.gem &>/dev/null
  gem fetch "$g" || abort 'Failed to fetch:'
}

## Testing
E=''
set -x

[[ -n "$FAS" ]] || {
  section 'SRPM'

  # check for buildroot availability
  for x in {1..16}; do
    mrn="${x}"
    mck --shell 'echo available' \
      | tee -a /dev/stderr \
      | grep -q '^available$' \
      && break

    [[ $x -eq 16 ]] && abort 'No buildroot is available'
  done

  section 'BUILD'
  for c in $CINIT; do
    mck -q $c
    sleep 1
  done

  srpm

  for c in *.src.rpm; do
    mck $c
    sleep 1
  done

  # In case we dont do this from gup.sh
  [[ -z "$KJ" ]] && {
    TP="$TP\n  - Koji build:"
    KJ="`bash -c "$MYD/pkgs/kj-build.sh -q -s"`" \
      && TP="$TP ok" \
      || TP="$TP `fail "$KJ"`"
  }
}

section 'TESTS'
[[ -r "$bl" ]] || {
  [[ -r "${bl}.xz" ]] && unxz "${bl}.xz"
}
[[ -r "$bl" ]] || abort "Could not find build log: ${bl}"

TP="$TP\n  - Tests:"
grep -q '^Executing(%check)' "$bl" && {
  z="$(grep -E ' (assertions|examples)' "$bl")"

  [[ -n "$z" ]] \
    && ! grep -qE '(^|\s+)0 (assertions|examples)' <<< "$z" \
    && {
      ! grep ' failures' <<< "$z" || grep -E '(^|\s+)0 failures' <<< "$z" && {
      ! grep ' errors'   <<< "$z" || grep -E '(^|\s+)0 errors'   <<< "$z" \
        && TP="$TP ok" \
        || TP="$TP `fail "errors occured"`"
        :
      } || TP="$TP `fail "failures occured"`"
      :
    } || TP="$TP `fail "no assertions"`"
  :
} || TP="$TP `fail "%check is missing"`"

section 'INSTALL'
mar=''
x="$(find result -name "*.fc${rel}.noarch.rpm" -o -name "*.fc${rel}.x86_64.rpm")"
[[ -n "$x" ]] && {
  mck -i $x || E="Installation `fail "$x"`"
  :
} || {
  E="Installation `fail "no packages to install"`"
}

section 'SYNTAX'
TP="$TP\n  - Syntax check:"
mck --unpriv --shell '
  cd
  find -type f -name "*.rb" \
    | xargs -i bash -c \
      "{ ruby -c \"{}\" 2>&1 || exit 255 ; } | grep -v \"^Syntax OK$\""
  :
' && TP="$TP ok" || TP="$TP `fail`"

section 'DEPENDENCIES'
bash -c "$MYD/gems/whatrequires.sh -a '$g'" \
  || abort 'Failed to get reverse dependencies.'

TP="$TP\n  - Reverse dependencies:"
DEP="$( bash -c "$MYD/gems/whatrequires.sh -q '$g'" )" \
  || abort 'Failed to get reverse dependencies (2).'
[[ -z "$DEP" ]] \
  && TP="$TP ok" \
  || TP="$TP `fail -s "$DEP"`"

[[ -n "$E" ]] || {
  section 'SMOKE'
  TP="$TP\n  - Smoke test:"
  q="`sed -e 's/\-/\//' <<< "$g"`"
  q="`sed -e 's/^ruby//' <<< "$q"`"
  q="`tr '[:upper:]' '[:lower:]' <<< "$q"`"

  for c in "rpm -q \"$p\"" "ruby -e \"require '\''$g'\''\" || ruby -e \"require '\''$q'\''\"" 0 ; do
    [[ "$c" == '0' ]] \
      && TP="$TP ok" \
      || {
        mck --unpriv --chroot "$c" || {
          TP="$TP `fail "$c"`"
          break
        }
      }
  done
}

section 'RPMLINT'
TP="$TP\n  - rpmlint:"
RPML="$(
  rpmlint result/*.rpm *.spec 2>/dev/null \
    | grep -vE ' W: (no\-documentation)$' \
    | grep -vE ' W: (spelling\-error|zero\-length|devel\-file\-in\-non\-devel\-package) ' \
    | grep -vE ' W: (invalid-url Source)' \
    | sort -u
  )" \
  && TP="$TP ok" \
  || TP="$TP `fail "$RPML"`"

{ set +x; } &>/dev/null

section 'SUMMARY'
[[ -z "$KJ" ]] \
  && KJ="Build missing." \
  || KJ="https://koji.fedoraproject.org/koji/taskinfo?taskID=$KJ" \

[[ -z "$CR" ]] \
  && CR="Build missing." \
  || CR="https://copr.fedorainfracloud.org/coprs/build/$CR"

R=0
[[ -n "$E" ]] && {
  R=1
  TP="$TP\n  - Error: $E"
  :
} || E='Success'

echo -e "\n=> $E\n_ _ _ _\n\nrpmlint: $RPML\n"

} >&2
### REPORTING END ###


## Output Summary
cat <<EOLX | tee -a /dev/stderr

_ _ _ _

To have latest $g gem in Fedora.


Koji scratch-build:
$KJ

Copr build:
$CR

Checks:
$( echo -e "$TP" )

EOLX

exit $R
