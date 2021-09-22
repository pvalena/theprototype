#!/usr/bin/bash

set -xe
bash -n "$0"

# Args
[[ "$1" == "-r" ]] && {
  r=y
  shift
  :
} || r=


# Init
p=prep
s="$(ls *.spec)"


# Run prep in Mock
sed -i '/^%build/ i exit 7' "$s"

o="$(rock 2>&1)" \
  && f=1 || f=0

sed -i ':a;N;$!ba;s/\(\nexit 7\)\(\n%build\)/\2/' "$s"

[[ $f -eq 0 ]] || exit 2

d="$(grep '^DEBUG: \s*+ cd ' <<< "$o" | tail -n 1 | cut -d' ' -f4)"
[[ -n "$d" ]] || {
  echo "$o" >&2
  exit 4
}


# Cleanup previous run
[[ -d "$p" ]] && {
  ls "$p"

  [[ -n "$r" ]] || {
    {
      x=
      echo -n "Remove '$p'? "
      read -n1 x

    } 2>/dev/null

    [[ "$x" == "y" || "$x" == "Y" ]] || exit 5
  }
  rm -rf "$p"
}

# Copy prep from Mock
mkdir "$p"
cd "$p"

mck q --shell '
    tar c -C /builddir/build/BUILD \
      $(ls /builddir/build/BUILD | grep -v "^result$")
  ' \
  | tar x


# Setup git in prepped dir
[[ -d "$d" ]] || exit 3
cd "$d"

git init

gita -A

git commit -am init

echo
echo "$o"
