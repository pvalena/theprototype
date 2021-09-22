#!/usr/bin/zsh

grep -E '^%global\s*\S*_version [0-9]+\.[0-9]' *.spec | cut -d' ' -f2- | xargs -ri zsh -c "cd 'ruby-2.5.9' || exit 255; n=\"\$(cut -d'_' -f1 <<< '{}')\"; v=\"\$(cut -d' ' -f2 <<< '{}')\"; echo -e \"\n> \$n \$v\"; [[ -d lib/\$n\.rb ]] && { echo dir; exit; }; g=\"\$(find -type f -iname \"*\$n*gemspec\" | grep -v ^\./test | xargs -rn1 grep 's\.version = ')\"; [[ -n \"\$g\" ]] && {echo \"\$g\"; exit; }; g=\"\$(find -type f -iname \"*\${n}.rb\" | grep -v ^\./test | xargs -rn1 grep 'VERSION = ')\"; echo \"\$g\""

