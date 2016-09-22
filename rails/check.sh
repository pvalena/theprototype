#!/bin/bash
# Update presence check
# TODO: USAGE

 [[ "${1:0:1}" == "f" ]] && { D="$1" ; shift ; } || D="master"
 [[ "$1" ]] || exit 1

 for x in railties rails activesupport activerecord activejob actionview actionpack actionmailer actioncable activemodel; do
        echo -e "\n >>> $x"

        cd "rubygem-$x" || break
                fnd=

                while read z; do
                        grep " Update to ${x^} $1" <<< "$z" && fnd=y && break
                        echo "$z"

                done < <(git c $D &>/dev/null && git p &>/dev/null && git log --oneline -10)

                [[ "$fnd" ]] || {
                        echo "Update not found!" 2>&1

                }

        cd ..

 done

 echo
