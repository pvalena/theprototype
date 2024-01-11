#!/usr/bin/env zsh

[[ -n "$1" ]] && grep -q ^http <<< "$1" && {
  curl -sLkO "$1"
}

[[ -r result.json ]] || {
  echo "result.json"
  exit 1
}

jq '. | keys | .[]' result.json | xargs -ri zsh -c "z=\"\$(( jq '.{}[] | select(.result==\"BAD\") | .message' result.json || exit 255 ; jq '.{}[] | select(.result==\"VERIFY\") | .message' result.json ) | sort -u)\"; [[ -n \"\$z\" ]] && { echo; echo '>>> {}'; echo \"\$z\"; } ; "

