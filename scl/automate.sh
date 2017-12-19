
cat ../scl/rhel/list_rh-ror42/filter.lst | while read x; do cd ~/Work/RH/fedora ; echo "=== $x ===" ; cd "$x" || continue ; git c master ; git p ; fedpkg sources ; \
echo ; done

###

cat list_rh-ror42/filter.lst | while read x; do cd ~/Work/RH/scl/rhel || break ;  echo "=== $x ===" ; cd "$x" || { echo " ... NoDir ..." ; continue ; } ; \
git c rhscl-2.2-rh-ror41-rhel-7 || { cd .. ; echo "... Skipping ..." ; continue ; } ; cd .. ; cp -nR "$x" orig/ || break ; cd "$x" || break ; git c master || break ; \
git c -b rhscl-2.2-rh-ror42-rhel-7 || { echo "real baad" ; break ; } ; cd .. ; echo ; done

###

cat list_rh-ror42/filter.lst | while read x; do cd ~/Work/RH/scl/rhel || break ;  echo "=== $x ===" ; cd "$x" || { echo -e " ... NoDir ...\n" ; continue ; } ; \
git s | grep "On branch rhscl-2.2-rh-ror42-rhel-7" && git s | grep "nothing to commit, working directory clean" || { echo -e "... Skipping ...\n" ; continue ; } ; \
rm README || { echo -e "whoops\n" ; continue ; } ; [[ -d ~/Work/RH/fedora/$x/ ]] || { echo -e "WTF?\n" ; continue ; } ; cp ~/Work/RH/fedora/$x/* . || break ; done

###

git c rhscl-2.2-rh-ror42-rhel-7 && \
d="$(readlink -e ~/Work/RH/fedora/`pwd | rev | cut -d'/' -f1 | rev`/)" && [[ -d $d ]] && git b -u origin/rhscl-2.2-rh-ror42-rhel-7 && echo && ls && touch empty && \
rm -rf * && rm -f .gitignore && git a -A && git i -am "Initial package" && git p && cp $d/* . ; rpmdev-bumpspec *.spec && cp ../ruby/.gitignore . && \
spec2scl -i *.spec && git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` && git a -A && git i -am "Initial package" && git l && git s && pwd

###

x="`pwd | rev | cut -d'/' -f1 | rev`" && dff *.spec ../orig/$x/*.spec && dff *.spec ../cbs/$x/*.spec

###

git c rhscl-2.2-rh-ror42-rhel-7 && \
git c -b rhscl-2.2-rh-ror42-rhel-7_new && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
rm *.src.rpm ; rhpkg srpm && \
git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` --hard && \
git m rhscl-2.2-rh-ror41-rhel-7 && rhpkg import *.src.rpm && \
cp ../ruby/.gitignore . && git a .gitignore && \
git i -a ; git l -p

###

git c rhscl-2.2-rh-ror42-rhel-7 && \
d="$(readlink -e ~/Work/RH/fedora/`pwd | rev | cut -d'/' -f1 | rev`/)" && [[ -d $d ]] && git b -u origin/rhscl-2.2-rh-ror42-rhel-7 && echo && ls && touch empty && \
rm -rf * && rm -f .gitignore && git a -A && git i -am "Initial package" && git p && cp $d/* . ; rpmdev-bumpspec *.spec && cp ../ruby/.gitignore . && \
spec2scl -i *.spec && git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` && git a -A && git i -am "Initial package" && {
x="`pwd | rev | cut -d'/' -f1 | rev`" && ls ../orig/$x/*.spec && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
git c -b rhscl-2.2-rh-ror42-rhel-7_new && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
rm *.src.rpm ; rhpkg srpm && \
git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` --hard && \
git m rhscl-2.2-rh-ror41-rhel-7 && rhpkg import *.src.rpm && \
cp ../ruby/.gitignore . && git a .gitignore && \
git i -a
} ; git l -p ; git s ; pwd

###

git c -b rhscl-2.2-rh-ror42-rhel-7 && \
d="$(readlink -e ~/Work/RH/fedora/`pwd | rev | cut -d'/' -f1 | rev`/)" && [[ -d $d ]] && echo && ls && touch empty && \
rm -rf * && cp -v $d/* . && rpmdev-bumpspec *.spec && cp ../ruby/.gitignore . && \
spec2scl -i *.spec && git a -A && git i -am "Initial package" && {
x="`pwd | rev | cut -d'/' -f1 | rev`" && ls ../orig/$x/*.spec && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
git c -b rhscl-2.2-rh-ror42-rhel-7_new && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
rm *.src.rpm ; rhpkg srpm && \
git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` --hard && \
git m rhscl-2.2-rh-ror41-rhel-7 && rhpkg import *.src.rpm && \
cp ../ruby/.gitignore . && git a .gitignore && \
git i -a
} ; git l -p ; git s ; pwd


###

git c rhscl-2.2-rh-ror42-rhel-7 && \
d="$(readlink -e ~/Work/RH/fedora/`pwd | rev | cut -d'/' -f1 | rev`/)" && [[ -d $d ]] && git b -u origin/rhscl-2.2-rh-ror42-rhel-7 && echo && ls && touch empty && \
rm -rf * && rm -f .gitignore && git a -A && git i -am "Initial package" && git p && cp $d/* . ; rpmdev-bumpspec *.spec && cp ../ruby/.gitignore . && \
spec2scl -i *.spec && git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` && \
ls | grep -E "\.(gz|tgz|xz|gem)$" | xargs rhpkg new-sources && git a -A && git i -am "Initial package" && {
x="`pwd | rev | cut -d'/' -f1 | rev`" && ls ../orig/$x/*.spec && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
git c -b rhscl-2.2-rh-ror42-rhel-7_new && \
git c rhscl-2.2-rh-ror42-rhel-7 && \
rm *.src.rpm ; rhpkg srpm && \
git r `git l --oneline | grep 'New branch setup' | cut -d' ' -f1` --hard && \
git m rhscl-2.2-rh-ror41-rhel-7 && rhpkg import *.src.rpm && \
cp ../ruby/.gitignore . && git a .gitignore && \
git i -a
} ; git l -p ; git s ; pwd

###

while :; do X="`brew list-tagged --latest rhscl-2.2-rhel-7-candidate | grep ^rh-ror42 | cut -d' ' -f1 | sort -u`" ; clear ; echo -e "\n" ; twocol -i 12 <<< "$X" ; sleep 7m ; done

###

brew list-tagged --latest rhscl-2.2-rhel-7-candidate | grep ^rh-ror42 | cut -d' ' -f1 | sort -u > real.lst ; kate real.lst

###

d="$(readlink -e ~/Work/RH/fedora/`pwd | rev | cut -d'/' -f1 | rev`/)" && [[ -d $d ]] && cp $d/* . ; cp ../rubygem-flexmock/.gitignore .

###

P="" ; while read x; do grep "^$P$" <<< "$x" ; P="$x" ; done < <(ls */*.gem | sort -u | cut -d'/' -f1) | sort -u | while read z; do echo "$z>>>" ; cat "$z/sources" ; echo ; done

###

cd ~/Work/RH/fedora && ls | while read x; do O="$x:" ; [[ -d ~/Work/RH/fedora/$x ]] || { echo "$O notadir" ; continue ; }
cd ~/Work/RH/fedora/$x || {  echo "$O FailtoCD" ; break ; } ; [[ -d .git/ ]] || { echo "$O NoGIT" ; continue ; }
git f &>/dev/null || { echo "$O FailedToFetch" ; continue ; }
git c master &>/dev/null || {  echo "$O FailedToMaster" ; continue ; }
git s | grep "^On branch master" >/dev/null || { echo "$O NOtOnBranch" ; continue ; }
rm -rf result *.src.rpm *\~ &>/dev/null
git s | grep "^nothing to commit, working directory clean" >/dev/null || { echo "$O NOtClean" ; continue ; }
git s | grep "^Your branch is up-to-date with 'origin/master'." >/dev/null && continue
[[ "$O" == "$x:" ]] && { git p &>/dev/null || { echo "$O PullFail" ; continue ; } ; } || echo "$O" ; done

###

cd ~/Work/RH/scl/rhel && ls | while read x; do O="$x:" ; [[ -d ~/Work/RH/scl/rhel/$x ]] || { echo "$O notadir" ; continue ; } ; cd ~/Work/RH/scl/rhel/$x || {  echo "$O FailtoCD" ; break ; } ; [[ -d .git/ ]] || { echo "$O NoGIT" ; continue ; } ; git c rhscl-2.2-rh-ror42-rhel-7 &>/dev/null ; git s | grep "^On branch rhscl-2.2-rh-ror42-rhel-7" >/dev/null || {  echo "$O NOtOnBranch" ; continue ; } ; git s | grep "^Your branch is up-to-date with 'origin/rhscl-2.2-rh-ror42-rhel-7'." >/dev/null ||  O="$O NOTuptodate" ; git s | grep "^nothing to commit, working directory clean" >/dev/null || O="$O NOtClean" ; [[ "$O" == "$x:" ]] || echo "$O" ; done | \
 grep -E " (NOTuptodate|NOtClean)"

###

ls *.* | grep -vE "(~|.xz|.patch)$" | while read f; do diff -q "$f" "../orig/ruby/$f" && continue ; echo "### $f ###" ; dff "$f" "../orig/ruby/$f" ; echo ; echo ; done

###

cd ~/Work/RH/scl/rhel && ls | while read x; do O="$x:" ; [[ -d ~/Work/RH/scl/rhel/$x ]] || { echo "$O notadir" ; continue ; } ; cd ~/Work/RH/scl/rhel/$x || {  echo "$O FailtoCD" ; break ; } ; [[ -d .git/ ]] || { echo "$O NoGIT" ; continue ; } ; git c rhscl-2.2-rh-ror42-rhel-7 &>/dev/null ; git s | grep "^On branch rhscl-2.2-rh-ror42-rhel-7" >/dev/null || {  echo "$O NOtOnBranch" ; continue ; } ; git s | grep "^Your branch is up-to-date with 'origin/rhscl-2.2-rh-ror42-rhel-7'." >/dev/null ||  O="$O NOTuptodate" ; git s | grep "^nothing to commit, working directory clean" >/dev/null || O="$O NOtClean" ; [[ "$O" == "$x:" ]] || echo "$O" ; done | \           grep -E " (NOTuptodate|NOtClean)" | cut -d':' -f1 | while read z; do yarun "cd ~/Work/RH/scl/rhel/$z && git l && git s"

##

while read l; do
cd ~/Work/RH/scl/rhel/ror || break
cd "$l" || break
git log --oneline | cut -d' ' -f2- | grep "^$MSG$" || {
git t ; MSG="Explicitly require runtime subpackage, as long as older scl-utils do not generate it"
sed -i '/Provides:\s\+%{?scl_prefix}rubygem(%{gem_name/ r /dev/stdin' *.spec << EOLX

# $MSG
Requires: %{scl_runtime}
EOLX
git i -am "$MSG"
}
git l -p
done < <( ~/Work/RH/my/scl/listpkgs.sh rhscl-2.3-rhel-7-build rh-ror42 )


###

git c -b rhscl-2.3-rh-ror42-rhel-6-bootstrap && \
git c rhscl-2.3-rh-ror42-rhel-6 && \
git r --hard origin/rhscl-2.3-rh-ror42-rhel-6 && \
git m 1d244e340e427899b6258f672d528371e8e47d0a -m "Merge branch 'rhscl-2.3-rh-ror42-rhel-7' into 'rhscl-2.3-rh-ror42-rhel-6'" && \
git y d7ab6ed726513b6dc88bc1e47538ef5ef673521a

###

clear ; while A="$(while read l; do
cd ~/Work/RH/scl/rhel/ror/$l || break
git f || { echo "FETCH_FAIL: $l" ; break ; }
git c rhscl-2.3-rh-ror42-rhel-6 2>&1 | grep "^Already on 'rhscl-2.3-rh-ror42-rhel-6'$" &>/dev/null || { echo "INVALID_BRANCH: $l" ; continue ; }
git s | grep '^nothing to commit, working directory clean$' &>/dev/null || { echo "NOT_COMMITED: $l" ; continue ; }
git s | grep 'branch is ahead' && { echo "NOT_PUSHED: $l" ; continue ; }
git d origin/rhscl-2.3-rh-ror42-rhel-7 | grep '^-Release: ' &>/dev/null && { echo "RELEASE_DIFF: $l" ; continue ; }
done < <( ~/Work/RH/my/scl/listpkgs.sh rhscl-2.3-rhel-6-build rh-ror42 ) | while read x; do echo -e "$x\n" ; done)" ; do
clear ; echo "$A" ; sleep 2m ; done
