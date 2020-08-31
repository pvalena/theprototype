#!/bin/bash

set -e
bash -n "$0"

PKGS="$(cd copr-r8-ruby-on-rails; cat *.log | tr -s '\t' ' ' | grep '^ Installing : rubygem\-' | cut -d' ' -f4 | rev | cut -d'-' -f3- | rev | sort -uR)"

pwd
f="failed.txt"
s="skipped.txt"
touch "$f" || exit 1
touch "$s" || exit 2

set +e
for p in ${PKGS}; do
  P="$(dnf repoquery whatprovides --qf '%{source_name}' "$p" 2>/dev/null | grep '^rubygem\-' | head -1)"

  [[ -z "$P" ]] && {
    grep -q "^$P$" "$s" \
      || echo "$P" >> "$s"
    continue
  }

  [[ -d "$P" ]] && {
    grep -q "^$P$" "$f" \
      && {
        bash -c "set -xe; cd '$P'; git pull"
        :
      } || continue
  }

  echo -e "\n> $P"
  bash -c "set -xe; fedpkg co '$P' ||: ; cd '$P'; ~/lpcsf-new/test/scripts/pkgs/cr-build.sh -c ruby-on-rails 1>/dev/null" \
    && {
      tmp="$(grep -v "^$P$" "$f")"
      echo "$tmp" > "$f"
      :
    } || {
      grep -q "^$P$" "$f" \
        || echo "$P" >> "$f"
    }
  sleep 5
done
