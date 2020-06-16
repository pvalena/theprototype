#!/bin/zsh
#
# gen.sh SONGS [GENRE TEMPERATURE TRUNCTATION LENGTH]
#
# You'll get number of SONGS times four.
#
# Requirements:
#           base64 shuf curl jq
#
# Examples:
#           ./gen.sh 1 _ _ 27 400      # default
#           ./gen.sh 3 bach
#           ./gen.sh
#

set -e
zsh -n "$0"
set +e

die () {
  echo "Error:" "$@" 1>&2
  exit 1
}

GS="chopin mozart rachmaninoff ladygaga country disney jazz bach beethoven journey thebeatles video broadway franksinatra bluegrass tchaikovsky"
TS="`seq 0 7`"
myd="$(dirname "$0")"

# Args
[[ "$1" == '-r' ]] && {
  P="$2"
  shift 2
  :
} || P=3

[[ -n "$1" ]] && {
  z="$1"
  shift
  :
} || z=1

# Nr of songs = 4*z
for l in {1..$z}; do

genr="$1"
temp="$2"
trun="$3"
leng="$4"

[[ -n "$genr" && "$genr" != "_" ]] && {
  [[ -z "$(echo "$GS" | tr -s ' ' '\n' | grep "^${genr}$")" ]] && die "Unknown genre: $genr"
  :
} || genr="$(shuf -n 1 -e `echo $GS`)"

[[ -n "$temp" && "$temp" != "_" ]] \
  || temp="$(shuf -n 1 <<< "$TS")"

# Name
G="${genr}_${temp}"

[[ -n "$trun" && "$trun" != "_" ]] && {
  G="${G}_r${trun}"
  :
} || trun=27

[[ -n "$leng" && "$leng" != "_" ]] && {
  G="${G}_l${leng}"
  :
} || leng=400

for x in {1..1000}; do
  f="${G}-${x}"
  [[ -f "${f}-1.mp3" ]] && continue

  # On failure
  E=1
  for i in {1..$P}; do
    set -x

    ${myd}/cmd_scratch.sh "$f" "$genr" "$temp" "$trun" "$leng"
    R=$?

    { set +x; } &>/dev/null

    [[ $R -eq 0 ]] && E=0 || continue
    break
  done

  [[ $E -eq 0 ]] || die "Failed to generate song!"
  break
done

echo
done
exit 0
