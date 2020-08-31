#!/bin/zsh

set -e
zsh -n "$0"

[[ "$1" == "-d" ]] && {
  set -x
  DEBUG="$1"
  shift
}

[[ "$1" == "-i" ]] && {
  I="$2"
  shift 2
  :
} || I=1

[[ "$1" == "-l" ]] && {
  me="$(readlink -e "$0")"
  exec noploop -v -w 1h \
    "${me} $DEBUG -i $I" \
}

[[ -z "$1" ]] || exit 2

x=pvalena
d="redhat.com"

f=34
lst="$(readlink -e ~/lpcsf-new/test/scripts/pkgs/list.sh)"
bld="$(readlink -e ~/lpcsf-new/test/scripts/pkgs/bld.sh)"

[[ -x "$lst" ]]
[[ -x "$bld" ]]

[[ -z "$DEBUG" ]] && silt=x || silt=''

gsgr="git status -uno | grep -q"
fail="{ pwd; git status -uno; exit 255; }"
silt="{ set +e${silt}; } &>/dev/null"
verb="set -xe"

gems="$($lst -a -f -k f34 "rubygem-")"

eval $silt
read -r -d '' MAIN << EOM
  set -e
  [[ -n "$DEBUG" ]] && set -x
  sleep "$I"

  next () {
    echo -e "\n>>> {}"
    echo "> Skipping:" "\$@" >&2
    exit 1
  }

  cd '{}'
  [[ -r .skip ]] && next 'Explicitly (.skip file)'

  git fetch origin &>/dev/null || $fail

  $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
  $gsgr '^Your branch is ahead' && next 'Branch is ahead'
  $gsgr '^Your branch and ' && next 'Branch has diverged'

  $gsgr '^nothing to commit ' || next 'Uncomitted changes'

  $gsgr '^On branch master$' || {
    git checkout master &>/dev/null || next 'Failed to checkout'
    $gsgr '^On branch master$' || next 'Wrong branch'
  }

  git rebase origin/master &>/dev/null || next 'Failed to rebase'
  #  | grep -q '^Successfully rebased and updated'
  $gsgr "^Your branch is up to date with 'origin/master'" || next 'Outdated branch'

  $silt
  # version-release
  v="\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev |cut -d' ' -f1 | rev)"

  # current built NVR
  exp="\$(sed -e 's/\({}-\)[0-9]*:/\1/' <<< "{}-\${v}")"
  nvr="\$(grep "^\${exp}\.fc[0-9][0-9]" <<< "$gems")"

  [[ -n "\$nvr" ]] && {
    [[ -n "$DEBUG" ]] && echo "> Up-to-date: \${nvr}"
    exit 0
  }

  echo -e "\n>>> {}"
  echo "> Expected NVR like: \${exp}"
  echo -n '> Current NVR: '
  grep -E '^{}-[0-9]' <<< "$gems" || $fail

  # changelog email
  e="\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev | cut -d' ' -f3 | rev)"

  # commit email
  a="\$(git log -1 origin/master | head -2 | tail -n 1 | rev | cut -d' ' -f1 | rev)"
  $verb

  [[ "\$e" == "<${x}@${d}>" ]]
  [[ "\$e" == "\$a" ]]

  $silt
  # commit hash
  c="\$(git log -1 origin/master | head -1 | cut -d' ' -f2)"

  # add fork
  {
    git fetch "$x" || {
      git remote remove "$x"
      git remote add "$x" "ssh://$x@pkgs.fedoraproject.org/forks/$x/rpms/{}.git"
      git fetch "$x"
    }
  } &>/dev/null
  r="\$(git log -1 $x/rebase | head -1 | cut -d' ' -f2)"
  $verb

  [[ "\$c" == "\$r" ]]

  # safety checks
  [[ -n "\$c" ]] || $fail
  [[ -n "\$v" ]] || $fail
  [[ -n "\$e" ]] || $fail

  $silt
  echo -e "\n> Build New Update"

  # In case sources are elsewhere
  find "../../packages/{}/" \
      -maxdepth 1 \
      -name '*.tar.gz' -o \
      -name '*.tar.xz' -o \
      -name '*.tgz' -o \
      -name '*.txz' \
    | xargs -rI'[]' echo cp -nv "[]" .

  $bld -b master -r -s || exit 255

  echo -e "\n> Update suceeded"
  rm -f ".update"
  rm -f "../../packages/{}/.update"
EOM

bash -c -n "$MAIN" || exit 3

ls -d rubygem-*/*.spec | cut -d'/' -f1 | sort -uR \
  | xargs -i bash -c "$MAIN" 2>&1 \
  | grep -v '^+ git status -uno$'
