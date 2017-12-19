#!/bin/bash

  . lpcsbclass

 exit

def GRC () { echo "-->$1: " ; x="gem compare -bk \"$1\" 4.2.4 _" ; eval "$x" ; echo ; echo ; [[ "$2" == "-n" ]] && return ; eval "$x" | tr -s ' ' | cut -f2 -d' ' | grep -viE "^(versions|DIFFERENT|[0-9]\.|\*|Compared)" | while read v; do GRC "$v" -n ; done ; } ; GRC rails

 [[ "$1" ]] || die "Command missing"

 C="$1"

 until :; do
 	P="`mock -q --chroot "timeout --signal=SIGINT 10s $C" 2>/dev/null | grep "Bundler::GemNotFound" | cut -d' ' -f9`"

 	[[ "$P" ]] || die "Break"

	P="rubygem-${P:1}"

 	echo "$P"

 	mock -qi "$P" || die "Install '$P'"

 done

 exec mock -q --chroot "$C"
