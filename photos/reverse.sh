#!/usr/bin/bash

set -e
bash -n "$0"

AR='y'
AL=''

[[ "${1:0:1}" == "-" ]] && {
	case "${1:1:1}" in 
		[lL])
			AR=''
			AL='y'
			;;

		[bB])
			AL='y'
			;;

	esac

}

O=''
L=''
NL="
"

while read Line; do
	[[ "$AR" ]] && {
		L=''
		N="`echo "$Line" | wc | tr "\t" ' ' | tr -s ' ' | cut -d' ' -f3`"

		for i in `seq $N -1 1`; do
			L="$L`echo $Line | cut -d' ' -f$i` "

		done
	
	} || {
		L="$Line"	

	}

	L="$L$NL"
	
	[[ "$AL" ]] && {
		O="$L$O"

	} || {
		O="$O$L"

	}

done

echo -n "$O"

