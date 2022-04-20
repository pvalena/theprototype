#!/bin/zsh

# -l      run in a loop - must be always last

set -e
zsh -n "$0"

abort () {
  echo "Error:" "$@" >&2
  exit 1
}

[[ "$1" == "-d" ]] && {
  set -x
  DEBUG="$1"
  INFO="$1"
  shift
  :
} || DEBUG=

[[ "$1" == "-i" ]] && {
  I="$2"
  shift 2
  :
} || I=1

[[ "$1" == "-l" ]] && {
  LOOP=y
  shift
  :
} || LOOP=

# More information on skipped packages
[[ "$1" == "-v" ]] && {
  INFO="$1"
  shift
}

[[ "${1:0:1}" == '-' ]] && abort "Unknown arg: '$1'"

[[ -n "$LOOP" ]] && {
  me="$(readlink -e "$0")"
  clear
  exec noploop -w 1h \
    "${me} $DEBUG -i $I $INFO" \
}

x=pvalena
d="redhat.com"
s="lpcs@lpcsn:/`pwd | cut -d'/' -f7-`"
f=rawhide
or=origin
ma=rawhide

myd="$(readlink -e "$0")"
myd="`dirname "$(dirname "$myd")"`"
lst="${myd}/pkgs/list.sh"
bld="${myd}/pkgs/bld.sh"
gpi="${myd}/fedora/get_pr_id.sh"
gpc="${myd}/fedora/get_pr_comments.sh"
mpr="${myd}/fedora/merge_pr.sh"

[[ -x "$lst" ]]
[[ -x "$bld" ]]
[[ -x "$gpi" ]]
[[ -x "$gpc" ]]

[[ -z "$DEBUG" ]] && silt=x || silt=''

gsgr="git status -uno | grep -q"
fail="{ echo; pwd; git status -uno; exit 255; }"
silt="{ set +e${silt}; } &>/dev/null"
verb="set -xe"

klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' \
  || abort 'KRB missing!'

gems="$($lst -k ${f} "rubygem-")"

eval $silt
read -r -d '' MAIN << EOM
  set -e
  [[ -n "$DEBUG" ]] && set -x

  next () {
    echo -e "\n>>> {}"
    echo ">> Skipping:" "\$@" >&2
    echo
    exit 1
  }

  info () {
    [[ -n "$INFO" ]] && {
      echo -e ">>> {}:" "\$@"
    }
  }

  sleep "$I"
  cd '{}'

  git fetch origin &>/dev/null || {
    sleep 1
    git fetch origin &>/dev/null || $fail
  }
  ls *.spec &>/dev/null || $fail

  $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
  $gsgr '^Your branch is ahead' && next 'Branch is ahead'
  $gsgr '^Your branch and ' && next 'Branch has diverged'

  $gsgr '^nothing to commit ' || next 'Uncomitted changes'

  $gsgr "^On branch ${ma}$" || {
    git checkout "${ma}" &>/dev/null || next 'Failed to checkout'
    $gsgr "^On branch ${ma}$" || next 'Wrong branch'
  }

  git rebase "origin/${ma}" &>/dev/null || next 'Failed to rebase'
  #  | grep -q '^Successfully rebased and updated'
  $gsgr "^Your branch is up to date with 'origin/${ma}'" || next 'Outdated branch'

  mer=
  w='[\s \.,\-\!]*'
  for i in \$($gpi -g '^Update to '); do
    [[ -n "\$($gpc -g "^\${w}LGTM\${w}" -i "\$i")" ]] && {
      info "Approved PR found: \$i"

      m="\$($mpr -i "\$i")" || next "Failed to merge the PR: \$m"

      [[ "\$m" == 'Changes merged!' ]] || next "Failed to merge the PR (2): \$m"

      sleep 5

      git fetch origin &>/dev/null || $fail
      git rebase "origin/${ma}" &>/dev/null || next 'Failed to rebase after merge'
      $gsgr "^Your branch is up to date with 'origin/${ma}'" || next 'Outdated branch after merge'

      mer="\$i"
      break
      :
    } || {
      info 'Update pending, no LGTM yet.'
    }
  done

  ls *.spec &>/dev/null || $fail

  $silt
  # version-release
  v="\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev |cut -d' ' -f1 | rev)"

  # current built NVR
  exp="\$(sed -e 's/\({}-\)[0-9]*:/\1/' <<< "{}-\${v}")"
  nvr="\$(grep "^\${exp}\.fc[0-9][0-9]" <<< "$gems")"

  [[ -n "\$nvr" ]] && {
    [[ -n "$DEBUG" ]] && echo "> Up-to-date: \${nvr}"
    [[ -z "\$mer" ]] || $fail
    exit 0
  }

  # changelog email
  e="\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev | cut -d' ' -f3 | rev)"

  # commit email
  a="\$(git log -1 "origin/${ma}" | head -2 | tail -n 1 | rev | cut -d' ' -f1 | rev)"

  [[ "\$e" == "\$a" ]] || {
    [[ -z "\$mer" ]] || $fail

    m="Email inconsistency: '\$e' vs '\$a')"

    grep -i valena <<< "\$e:\$a" \
      && next "\$m"

    info "\$m"
    exit 0
  }

  m="<${x}@${d}>"
  [[ "\$e" == "\$m" ]] || {
    [[ -z "\$mer" ]] || $fail

    info "Email mismatch: '\$e' vs '\$m'"
    exit 0
  }

  [[ -r .skip ]] && {
    next 'Explicit skip'
    exit 0
  }

  echo -e "\n>>> {}"
  [[ -z "\$mer" ]] && {
    echo ">> Expected NVR like: \${exp}"
    echo -n '>> Current NVR: '
    grep -E '^{}-[0-9]' <<< "$gems" || $fail
    :
  } || {
    echo ">> Merged PR: #\$mer"
  }

  # commit hash
  c="\$(git log -1 "origin/${ma}" | head -1 | cut -d' ' -f2)"

  # add fork
  {
    git fetch "$x" || {
      git remote remove "$x"
      git remote add "$x" "ssh://$x@pkgs.fedoraproject.org/forks/$x/rpms/{}.git"
      git fetch "$x"
    }
  } &>/dev/null
  r="\$(git log -1 $x/rebase | head -1 | cut -d' ' -f2)"

  [[ "\$c" == "\$r" ]] || {
    echo -e ">> Commit mismatch: '\$c', '\$r'\n"
    exit 1
  }

  $verb

  # safety checks
  [[ -n "\$c" ]] || $fail
  [[ -n "\$v" ]] || $fail
  [[ -n "\$e" ]] || $fail

  $silt
  date -Isec
  echo -e "\n>> Build New Update"

  # Get sources from second computer
  rsync -a --progress "${s}/{}/*.txz" . ||:
  rsync -a --progress "${s}/../packages/{}/*.txz" . ||:

  # In case sources are elsewhere
  find "../../packages/{}/" \
      -maxdepth 1 \
      -name '*.tar.gz' -o \
      -name '*.tar.xz' -o \
      -name '*.tgz' -o \
      -name '*.txz' -o \
      -name '*.gem' \
    | xargs -rI'[]' cp -v "[]" .

  # In case the gem file is still not present
  gem fetch "\$(cut -d'-' -f2- <<< '{}')" ||:

  $bld -b "${ma}" -r -s || exit 255

  echo -e "\n>> Update suceeded"
EOM

bash -c -n "$MAIN" || abort "Syntax check failed!"

[[ -z "$1" ]] && {
  ls -d rubygem-*/*.spec | cut -d'/' -f1 | sort -u \
    | xargs -i bash -c "$MAIN" 2>&1 \
    | grep -v '^+ git status -uno$'
  :
} || {
  ls -d "$@" | cut -d'/' -f1 | sort -u \
    | xargs -i bash -c "$MAIN" 2>&1 \
    | grep -v '^+ git status -uno$'
}

exit 0
