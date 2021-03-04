#!/usr/bin/zsh

grep http stage.html | grep -v 'a href="https://videojs.com/html5-video-support' | tr -s ' ' '\n' | grep -v ^$ | tr -s '"' '\n' | grep '^https' | sort -u | xargs -i zsh -c "for x in {1..100}; do f=\"\${x}.mp4\"; [[ -r "\$f" ]] && continue; fastdown -O "\$f" -n '{}'; break; done"
