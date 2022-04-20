#!/bin/zsh
#
# ./check-update.sh
#
#   Browses all directories in this folder, and tries to attempt the package
#   using `gems/run.sh -u`.
#   Before that, it checks the repository status for uncommited / unpushed
#   changes etc., and halts if anything is found.
#
#
#   Re-run with '-d' on failures.
#
#   Run with '-i TIME' if you want more to change
#     sleep TIME in between the respective update attempts.
#
#   Run with `-l` to run using `noploop -v` (see scripts).
#

set -e
zsh -n "$0"

[[ "$1" == "-d" ]] && {
  set -x
  DEBUG="$1"
  shift
}

[[ "$1" == "-i" ]] && {
  I="$2"
  timeout 1 sleep "$I" || R=$?
  [[ $R -eq 124 ]] || exit 4
  shift 2
  :
} || I=1

[[ "$1" == "-l" ]] && {
  me="$(readlink -e "$0")"
  exec aux "${me} $DEBUG -i $I"
}

[[ "${1:0:1}" == '-' ]] && exit 2

x=pvalena
f="$(readlink -f cpr/update_failed.txt)"
touch "$f"

run="$(readlink -e `dirname "$0"`/run.sh)"

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

  msg () {
    local m="\$1"
    shift
    echo -e "\n>>> {}" "\n>> \${m}:" "\$@"
  }

  next () {
    msg "Skipping" "\$@" >&2
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

  $gsgr '^Your branch is behind' && {
    $gsgr '^On branch rebase$' && git rebase "$x/rebase"
    $gsgr '^On branch rawhide$' && git rebase origin/rawhide
  }

  #$gsgr '^Your branch is behind' && next 'Branch is behind'
  $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
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
    git rebase origin/rawhide &>/dev/null || next 'Failed to rebase'
    #  | grep -q '^Successfully rebased and updated'

    $gsgr '^Changes not staged for commit' && next 'Unstaged changes'
    $gsgr '^Your branch is behind' && next 'Branch is behind'
    $gsgr '^Your branch and ' && next 'Branch has diverged'

    $gsgr '^nothing to commit ' || next 'Uncomitted changes'

    git branch -u "${x}/rebase"

    $gsgr "^Your branch is up to date with '${x}/rebase'" || next 'Outdated branch'
  }

  O="\$(
      echo -e "\n>>> {}"
      $run -u 2>&1
    )"
  R=\$?

  cd ..
  p="\$(cut -d'-' -f2- <<< '{}')"
  cpr="cpr/{}_update.log"

  [[ -r "\$cpr" ]] && {
    [[ \$R -eq 0 ]] && {
      msg "Success" "Package updated"
    }

    [[ \$R -eq 2 ]] && {
      tail -n 3 "\$cpr" | grep -q '^\-\-> Version is current\: ' \
        && R=0
    }

    [[ \$R -eq 0 ]] && {
      tmp="\$(grep -v "^{}$" "$f")"
      echo "\$tmp" > "$f"
      exit 0
    }
    :
#  } || {
#    msg "Error" "Package update log not found:" "\$cpr"
  }

  echo "\$O"

  grep -q "^{}$" "$f" \
    || echo "{}" >> "$f"
EOM

bash -c -n "$MAIN" || exit 3

[[ -z "$1" ]] && {
  ls -d rubygem-*/*.spec \
    | cut -d'/' -f1 \
    | sort -uR \
    | xargs -i bash -c "$MAIN" 2>&1 \
    | tee -a "cpr/update_`date -I`.log"
  :
} || {
  ls -d "$@" \
    | cut -d'/' -f1 \
    | sort -uR \
    | xargs -i bash -c "$MAIN" 2>&1 \
    | tee -a "cpr/update_`date -I`.log"
}

