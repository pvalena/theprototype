#!/bin/bash

set -e
abort () {
  echo "Error:" "$@" >&2
  exit 1
}
set +e

abort "I decided to use pure ruby upload instead, see run_upload.rb"

bash -n "$0"

TL="$(readlink -e "$1")"
[[ -n "$TL" && -r "$TL" ]] || abort 'No talks list found!'
shift

T="$(readlink -e "$1")"
[[ -n "$T" && -d "$T" ]] || abort 'No path to videos specified!'
cd "$T" || abort 'Failed to CD!'

while read talk ; do
  [[ -z "$talk" ]] && continue
  echo -ne "\n\n>>> $talk"
  echo 'Fetching Associated data...'

  O="$(fetch_data.rb "$talk")"

  echo "$O"
done < "$TL"
