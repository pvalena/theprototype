#!/bin/zsh
#
# Use gen.sh ;)
#

set -e
zsh -n "$0"
set +e

[[ $# -lt 5 ]] && exit 4

N="${1}"
G="${2}"
T="${3}"
R="${4}"
S="${5}"

J="${N}.json"

[[ -r "${N}-1.mp3" ]] && exit 2
[[ -r "${J}" ]] && exit 3

curl -s 'https://musenet.openai.com/sample' -H 'authority: musenet.openai.com' -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36' -H 'dnt: 1' -H 'content-type: application/json' -H 'accept: */*' -H 'origin: https://openai.com' -H 'sec-fetch-site: same-site' -H 'sec-fetch-mode: cors' -H 'sec-fetch-dest: empty' -H 'referer: https://openai.com/blog/musenet/' -H 'accept-language: cs-CZ,cs;q=0.9,en-US;q=0.8,en;q=0.7,sk;q=0.6' --data-binary \
    '{"genre":"'${G}'","instrument":{"piano":true,"strings":false,"winds":false,"drums":false,"harp":false,"guitar":false,"bass":false},"encoding":"","temperature":'$T',"truncation":'$R',"generationLength":'${S}',"audioFormat":"mp3"}' --compressed \
  > "${J}"

[[ "`du "$J" | tr -s '\t' ' ' | cut -d' ' -f1`" -lt 100 ]] && {
  rm "${J}"
  sleep 1
  exit 1
}

i=0
jq ".completions[].audioFile" < "$J" \
  | cut -d "'" -f2 \
  | while read dat; do
      let "i += 1"

      f="${N}-${i}.mp3"
      echo "$dat" | base64 -d > "$f"
#      du "$f"
    done

rm "${J}"
exit 0
