#!/bin/bash
#
# ./rebuild.sh [options] \
#     -p SCLVERSION -n SCLNAME -s RHELVERSION \
#     [PACKAGE1 [PACKAGE2 [...]]]
#
#   Rebuilds packages in brew: on another branch, with another prefix, scl name or RHEL version.
#   You need a valid kerberos ticket.
#   Also does a scratch-build prior to git push. See 'Options' below.
#
#   If no PACKAGE is specified, the script will get from brew all packages with SCL prefix tagged
#   as 'from'.
#
#   Has builtin locking system, so multiple instances could be run tu speed up process.
#
# Mandatory:
#   -p SCLVERSION    prefix, e.g. 'rhscl-2.3'
#   -n SCLNAME       SCL name, e.g. 'rh-ruby23'
#   -s RHELVERSION   suffix, e.g. 'rhel-7'
#
#   !! At least one of the 'Mandatory' args has to contain bash expansions,   !!
#   !! Recommended syntax is '{from,to}' and you have to write it in quotes.  !!
#   !! (F.e.: 'rhscl-2.{2,3}')                                                !!
#
# Optional:
#   -r RUNS=7        number of times to run (loop) if no builds succeed, default is 7
#   -l DIRECTORY=.   location, i.e. working directory, default is current
#   -o OMITLIST      packages which should be ignored, comma or | separated list, default is empty
#   -c COMMAND       command to run after git preparation
#
# Boolean options:
#   -d    debug (verbose) mode
#   -b    push to remote repo and run the build
#   -e    prepare for building, no remote changes
#   -f    skip scratch-build
#   -y    use cherry-pick to merge commits istead of merge
#   -w    do extra scratch-build for FROM branch target
#
# Options and arguments are case insensitive, but their values are not.
#   F.e. following have the same meaning:
#     -e     and   -E
#     -r 3   and   -R 3
#
# Examples:
#   
#
#
###########


  . lpcsbclass #<<<<<<<<

 cdb () {
  cd "$1" || { ems "$x" EBAS fail ; }

 }

 ems () {
  local n
  [[ "$1" == "-" ]] || {
    n="[$1] "

    [[ "$3" == "-" && -z "$4" ]] || {
      isme "$KFL" && {
        rm -f "$KFL"
        debug "lock removed"

      }

    }

  }

  shift

  local m
  local s=Success
  local f=

  debug "ems: >$1< >$2< >$3<"

  [[ "${1:0:1}" == "E" ]] && {
    m=Error

  } || {
    m=$s
    [[ "$2" == "-" ]] || LOK="$LOK|$x"

  }

  E="${1:1}"

  [[ "$2" ]] && {
    [[ "$2" == "-" ]] && {
      shift

    } || {
      m="FATAL $m"
      f=y

    }

  }

  local o="`emsx "$1" "$n$m" "$2" 2>&1`"
  local c=$?

  [[ "$m" == "$s" && $c -eq 0 ]] && echo "$o" || echo "$o" 1>&2
  sleep 0.5
  [[ "$f" ]] && exit 1

  return $c

 }

 emsx () {
  echo -ne "\n$2: "

  local r=0

  case "$E" in
    BAS) P="Failed to 'cd' to base directory" ;;
    REA) P="Failed to resolve base directory" ;;
    CRA) P="scratch-built the package" ;;
    FIN) P="pushed and real-built the package" ;;
    PRE) P="prepared the git repo" ;;
    SAM) P="From and to branches names are same" ;;
    FAL) P="Finished" ;;
    BRI) P="Failed to checkout to destination branch" ;;
    SCR) P="Failed to scratch-build the package" ;;
    FAI) P="The following packages failed: $3" ;;
    TOM) P="Failed to build packages: $3" ;;
    DEP) P="Dependency is missing: $3" ;;
    DEW) P="Dependency is currently unavailable: $3" ;;
    NCO) P="Packages built in this run: $3" ;;
    NOK) P="No packages were built in this run" ;;
    ALR) P="Package is already built: $3" ;;
    NOS) P="No packages to rebuild" ;;

    *) P="Unknown. Code: $E ('$3')" ; r=1 ;;

  esac

  echo "$P"

  return $r

 }

 exp () {
  [[ "$1" ]] || { ems "$x" EEXP fail ; }

  local s

  eval "s=\"\$$1\""

  s="`eval "echo $s"`"

  [[ "`rest "$s"`" ]] || s="$s $s"

  debug "$1='$s'"
  eval "$1='$s'"

 }

 inl () {
  tr -s '\n' '-' | rev | cut -d'-' -f2- | rev

 }

 isme () {
  [[ "$1" && -r "$1" && -w "$1" ]] || return 1

  for i in 1 2 3; do
    sleep 1

    RID="`cat "$1"`"
    [[ "$RID" == "$$" ]] || return 1

  done

  return 0

 }

 deps () {
  local z
  local D="$($MY/listpkgs.sh $DEBUG -k "`rest "$SCL" "$SUF" | inl`-candidate" "`rest "$NAM" | inl`")"
  local b

  debug "D='$D'"

  while read z; do
    debug "z='$z'"

    [[ -d "$BDI/$z" ]] || continue

    b="`grep -E "^${z}-[0-9]" <<< "$D"`" || { ems "$2" EDEP - "$z" ; return 1 ; }
    brew wait-repo --timeout=1 "${INT}-build" "--build=`rest "$NAM"`-$b" || { ems "$2" EDEW - "$z" ; return 1 ; }

  done < <(rpm -qRp "$1.src.rpm" | grep -v ^rpmlib | grep -v '^/usr/bin' | tr -s '(' '-' | tr -s ')' ' ' | cut -d' ' -f1)

  return 0

 }

 MY="$(readlink -e "`dirname "$0"`")"

 [[ "$MY" ]] || ems - EMYD fail

 DIR='.'
 SCL=
 NAM=
 SUF=
 BUI=
 RES=
 PRE=
 OMI=
 SKI=
 RUN=7
 COM=
 WAR=
 CHY=

 pargs "yY b CHY" "wW b WAR" "dD b DEBUG" "cC s COM" "fF b SKI" "bB b BUI" "eE b PRE" "rR n RUN" "lL s DIR" "pP s SCL" "oO s OMI" "nN s NAM" "sS s SUF" "- RES" - "$@"

 debug
 debug "====================================================="
 debug
 debug "RES='$RES'"

 exp SCL
 exp NAM
 exp SUF

 [[ "$SCL" && "$NAM" && "$SUF" ]] || usage
 [[ "$PRE" ]] && NPRE= || NPRE="-"
 [[ "$DEBUG" ]] && DEBUG='-d'

 FRO="`first "$SCL" "$NAM" "$SUF" | inl`"
 INT="`rest "$SCL" "$NAM" "$SUF" | inl`"
 MSG="Merge branch '$FRO' into '$INT'"

 debug "$MSG"

 [[ "$FRO" == "$INT" ]] && ems - ESAM fail

 BDI="`readlink -e "$DIR"`" || ems - EREA fail

 cdb "$BDI"

 LOG="rebuild-`date +"%s"`-out.log"
 exec > >(tee -ai "$LOG") 2> >(tee -ai "$LOG" >&2)

 aempty RES && {
  LIST="$MY/listpkgs.sh $DEBUG -r "`first "$SCL" "$SUF"--" # <<<<<< 
  S="$($MY/listpkgs.sh $DEBUG -r "`first "$SCL" "$SUF" | inl`-build" "`first "$NAM" | inl`" \
    | grep -vE "^(`tr -s ',' '|' <<< "$OMI"`)$")"

 } || S="$RES"

##

c=0
FST=y
LFA=
KFL='.rebuild-lock'

while [[ $c -lt $RUN ]]; do
 let 'c += 1'

 LST=
 LOK=

 debug "S='$S'"

 [[ "$S" ]] || ems - ENOS fail

 while read x; do
  cdb "$BDI"
  echo -e "\n--> $x (`date -I'ns'`)"

  [[ -d "$x" ]] || {
    rhpkg co "$x" || { ems "$x" ERCO ; continue ; }

  }

  [[ -d "$x" ]] || { ems "$x" EDIR ; continue ; }
  cd "$x" || { ems "$x" ECDF ; continue ; }

  [[ -f "$KFL" ]] && {
    isme "$KFL" || {
      RID="`cat "$KFL"`"
      ps -p $RID --no-header | grep "^$RID " && { ems "$x" ERID ; continue ; }

    }

  }

  echo "$$" > "$KFL"
  debug "lock written"

  isme "$KFL" || { ems "$x" ERME ; continue ; }

  [[ "$FST" ]] && {
    git stash || { ems "$x" ESTA ; continue ; }
    git checkout -f "$INT" || { ems "$x" EBRI ; continue ; }
    git pull || { ems "$x" EPUL ; continue ; }

    [[ "$CHY" ]] && {
      po=

      while read z; do
        ret="`git cherry-pick "$z" 2>&1`" || {
          grep '^The previous cherry-pick is now empty, possibly due to conflict resolution.$' <<< "$ret" || {
            ems "$x" ECHY
            po=y
            break

          }

        }

      done < <( git l --pretty=oneline --reverse --no-merges --first-parent "origin/$FRO" | cut -d' ' -f1 )

      [[ "$po" ]] && continue
      :

    } || {
      git log --oneline | cut -d' ' -f2- | grep "^$MSG$" || {
        git merge -m "$MSG" "origin/$FRO" || { ems "$x" EMER ; continue ; }

      }

    }

    [[ "$COM" ]] && {
      eval "$COM" || { ems "$x" ECOM ; continue ; }

    }

    ems "$x" SPRE $NPRE
    [[ "$PRE" ]] && continue

  } || {
    [[ "`git rev-parse --abbrev-ref HEAD`" == "$INT" ]] || { ems "$x" EBRA ; continue ; }

  }

  NVR="`rhpkg srpm 2>/dev/null | grep -v '^Downloading ' | grep -v '###' | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev`" || { ems "$x" ESRP ; continue ; }
  debug "NVR='$NVR'"

  brew buildinfo "`rest "$NAM"`-$NVR" | grep '^No such build: ' || { ems "$x" SALR - "$NVR" ; continue ; }

  LST="$LST|$x"

  deps "$NVR" "$x" || continue

  [[ "$SKI" ]] || {
    rm -f *.src.rpm
    rhpkg scratch-build --srpm || { ems "$x" ESCR ; continue ; }

  }

  [[ "$WAR" ]] && {
     rm -f *.src.rpm
     rhpkg scratch-build --srpm --target "${FRO}-candidate" || { ems "$x" EWAR ; continue ; }

  }

  [[ "$BUI" ]] || { ems "$x" SCRA ; continue ; }

  SRC=
  #SRC="`cat sources | tr -s '\t' ' ' | cut -d' ' -f2- | tr -s '\n' ' '`"
  #debug "SRC='$SRC'"

  [[ "$SRC" ]] && {
    xargs rhpkg new-sources $SRC || { ems "$x" ESOU ; continue ; }

  }

  git push || { ems "$x" EPUS ; continue ; }
  rhpkg build || { ems "$x" EBUI ; continue ; }

  ems "$x" SFIN

 done <<< "$S"

 FST=
 LFA="$LFA `grep -vE "^(${LST:1})$" <<< "$S" | tr -s '\n' ' '`"
 S="`tr -s '|' '\n' <<< "${LST:1}" | grep -vE "^(${LOK:1})$"`"

 [[ "$PRE" ]] && {
    [[ "$S" ]] && ems - EFPR "`tr -s '\n' ' ' <<< "$S"`"

    ems - SPAL - "`tr -s '|' ' ' <<< "${LOK:1}"`"
    exit 0

 }

 [[ "$BUI" ]] && {
  debug "LOK='$LOK'"

  [[ "$S" ]] && {
    [[ "$LOK" ]] && {
      c=0
      ems - SNCO - "`tr -s '|' ' ' <<< "${LOK:1}"`"
      sleep 30s

    } || {
      ems - ENOK
      sleep 5m

    }

    continue

   }

 } || {
   [[ "$S" ]] && ems "$x" EFAI "`tr -s '\n' ' ' <<< "$S"`"

 }

 ems - SFAL
 echo -e "\n[!] Skipped: $LFA"
 exit 0

done

 ems - ETOM "`tr -s '\n' ' ' <<< "$S"`"
