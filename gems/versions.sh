#!/usr/bin/zsh

set -e

ls ../*.spec

grep -E '^%global\s*\S*_version [0-9]+\.[0-9]' ../*.spec | cut -d' ' -f2- | xargs -ri zsh -c "n=\"\$(cut -d'_' -f1 <<< '{}')\"; v=\"\$(cut -d' ' -f2 <<< '{}')\"; echo -e \"\n> \$n \$v\"; [[ -d lib\/\$n\/ ]] && { pushd lib\/\$n\/ &>/dev/null; grep -r ' VERSION ='; grep -r '^VERSION =' popd &>/dev/null; }; g=\"\$(find -type f -iname \"*\$n*gemspec\" | grep -v ^\./test | xargs -rn1 grep 's\.version = ')\"; [[ -n \"\$g\" ]] && {echo \"\$g\"; exit; }; g=\"\$(find -type f -iname \"*\${n}.rb\" | grep -v ^\./test | xargs -rn1 grep 'VERSION = ')\"; echo \"\$g\""

