#!/bin/zsh

exit 1

while :; do A="$( echo -e "\n" ; cd ~/Work/RH/scl/rhel || { echo 'DN' ; break ; } ; for y in `ls | grep -v '.txt$'`; do cd ~/Work/RH/scl/rhel || break ; ls "$y" &>/dev/null || { echo -e "NE: $y" ; break \
; } ; cd "$y" || { echo "CD: $y" ; break ; } ; ll * &>/dev/null || { echo "FM: $y" ; break ; } ; git s | grep 'On branch rhscl-2.2-rh-ror42-rhel-7' &>/dev/null || { echo "RP: $y" ; break ; } ; git s | \
grep 'nothing to commit, working directory clean' &>/dev/null || echo "CI: $y" ; git s | grep 'Your branch is' &>/dev/null && { echo "ST: $y" ; } ; X="`grep ^Release *.spec | tr -s '\t' ' ' | cut -d' ' \
-f2 | cut -d'%' -f1 | grep -E "^[0-9]+$"`" || { grep -E "rubygem-(nokogiri|rspec-(core|expectations|mocks|support))" <<< "$y" &>/dev/null && continue ; echo "RL: $y" ; break ; } ; Y="`grep -E \
"^rh-ror42-$y-[0-9]+" ../ror42_list.txt`" || { grep '^rh-ror42$' &>/dev/null <<< "$y" && continue ; echo "NB: $y" ; break ; } ; grep "\-$X.el7$" &>/dev/null <<< "$Y" || { grep '^rubygem-aruba$' \
&>/dev/null <<< "$y" && continue ; echo " === $Y <> $X ===" ; } ; done )" ; clear ; echo "$A" ; sleep 30 ; done


find ~/Work/RH/fedora/packages -maxdepth 1 -mindepth 1 -type d | sort -R | while read z; do
cd "$z" || break
echo
git f &>/dev/null || { echo "$z" ; continue ; }
[[ -n "`git t list 2>&1`" ]] && echo "$z"
git c master &>/dev/null
git c master 2>&1 | grep "Already on 'master'" &>/dev/null || echo "$z"
git p &>/dev/null
git p 2>&1 | grep 'Already up-to-date.' &>/dev/null || echo "$z"
git s 2>&1 | grep 'nothing to commit, working directory clean' &>/dev/null || {
git s 2>&1 | grep 'nothing added to commit but untracked files present' &>/dev/null || echo "$z"
}
git s 2>&1 | grep 'On branch master' &>/dev/null || echo "$z"
git s 2>&1 | grep 'Changes not staged for commit' &>/dev/null && echo "$z"
git s 2>&1 | grep 'Your branch is behind' &>/dev/null && echo "$z"
done 2>&1 | grep -v '^WARNING: ' | sort -u
