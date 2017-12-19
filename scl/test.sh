#!/bin/bash
# WIP

 EPOPUP=n

  . lpcsbclass

 checkdebug "$1" && shift

 [[ "$1" ]] || die "Arg Missing"

exit 1

clear ; while read c; do r="rhscl-2.3-$c-rhel-6-x86_64" ; echo -e "\n--> $r"                  mock -r "$r" -q --init || break                mock -r "$r" -q -i curl $c-rubygem-{json,rail{,tie}s,jbuilder,sdoc,byebug,sass-rails,listen} https://brewweb.engineering.redhat.com/brew/taskinfo\?taskID\=11653865 || break                sudo cp ~/Work/RH/tmp2/runtest.sh /var/lib/mock/$r/root/builddir/ || break                    sudo chmod 0777 /var/lib/mock/$r/root/builddir/runtest.sh                                     mock -r "$r" -q -n --unpriv --chroot "cd && scl enable $c ./runtest.sh" && echo OK || { echo FAIL ; break ; }                                done < <( echo ruby193 | tr -s ' ' '\n' ) ; echo
