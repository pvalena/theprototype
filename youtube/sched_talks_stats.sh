#!/bin/zsh

grep '<br><a href="venue/' descriptions.html | cut -d'>' -f3 | cut -d'<' -f1 | grep ' Room' | wc -l

grep '<br><a href="venue/' descriptions.html | sort -u | cut -d'>' -f3 | cut -d'<' -f1 | grep ' Room' | xargs -i zsh -c "echo -n '{}: '; grep '<br><a href=\"venue/' descriptions.html | grep '{}' | wc -l"

