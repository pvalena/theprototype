#!/usr/bin/zsh

cat *.html | grep 'session_recording' | grep -v 'a href="https://videojs.com/html5-video-support' | tr -s ' ' '\n' | grep -v ^$ | tr -s '"' '\n' | grep '^/organi' | sort -u | wc -l
