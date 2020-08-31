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
f="$(readlink -f failed.txt)"
touch "$f"

run="$(readlink -e ~/lpcsf-new/test/scripts/gems/run.sh)"

[[ -x "$run" ]]
[[ -r "$f" ]]
[[ -d 'cpr' ]]

[[ -z "$DEBUG" ]] && silt=x || silt=''

gsgr="git status -uno | grep -q"
fail="{ pwd; git status -uno; exit 255; }"
silt="{ set +e${silt}; } &>/dev/null"
verb="set -xe"

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

  $silt
  {
    git remote -v | grep ^origin | grep -q '@pkgs.fedoraproject.org/rpms/' \
      || {
        git remote remove origin
        git remote add origin "ssh://${x}@pkgs.fedoraproject.org/rpms/{}.git"
      }
  } &>/dev/null

  git fetch origin &>/dev/null \
    || next 'Invalid remote'

  {
    git fetch "$x" || {
      git remote remove "$x"
      git remote add "$x" "ssh://$x@pkgs.fedoraproject.org/forks/$x/rpms/{}.git"
      git fetch "$x"
    }
  } &>/dev/null

  $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
  $gsgr '^Your branch is behind' && next 'Branch is behind'
  $gsgr '^Your branch and ' && next 'Branch has diverged'

  $gsgr '^nothing to commit ' || next 'Uncomitted changes'

  NEW=
  $gsgr '^On branch rebase$' || {
    git checkout rebase &>/dev/null && {
      $gsgr '^On branch rebase$' || next 'Wrong branch'
      :
    } || {
      git checkout rebase 2>&1 \
        | grep -q "^error: pathspec 'rebase' did not match any file(s) known to git" \
        || next 'Failed to checkout'

      NEW=yes
    }
  }

  [[ -z "$NEW" ]] || {
    git rebase origin/master &>/dev/null || next 'Failed to rebase'
    #  | grep -q '^Successfully rebased and updated'

    $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
    $gsgr '^Your branch is behind' && next 'Branch is behind'
    $gsgr '^Your branch and ' && next 'Branch has diverged'

    $gsgr '^nothing to commit ' || next 'Uncomitted changes'

    git push -u "$x" "rebase"

    $gsgr "^Your branch is up to date with '${x}/rebase'" || next 'Outdated branch'
  }

  echo -e "\n>>> {}"
  echo -e "> Trying New Update"

  $run -u \
    && {
      tmp="\$(grep -v "^{}$" "$f")"
      echo "\$tmp" > "$f"
    }

  cd ..
  p="\$(cut -d'-' -f2- <<< '{}')"
  cpr="cpr/\${p}-update.log"

  [[ -r "\$cpr" ]] \
    && tail -n 1 "\$cpr" | grep -q ' is current' \
    && exit 0

  grep -q "^{}$" "$f" \
    || echo "{}" >> "$f"
EOM

bash -c -n "$MAIN" || exit 3

ls -d rubygem-*/*.spec | cut -d'/' -f1 | sort -uR \
  | xargs -i bash -c "$MAIN" 2>&1 \
  | tee -a "cpr/update_`date -I`.log"
