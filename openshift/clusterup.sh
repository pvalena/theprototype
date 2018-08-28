#!/bin/bash
#
# ./clusterup.sh [--pretend|--clean] [WD [UR [AR]]]
#   --pretend   dry-run
#   --clean     remove previous instance
#
# Optional
#   WD    working (base) directory
#   UR    openshift url
#   AR    additional args
#

set -xe
bash -n "$0"

# 0 on successful login
oc_login () {
  # rhbz#1268126
  export KUBECONFIG="$WD/openshift-apiserver/admin.kubeconfig"
  ${oc} login -u system:admin $AR "$UR"
  export KUBECONFIG=

  ${oc} login -u developer -p developer $AR "$UR"
  ${oc} status
  rc=$?

  [[ -n "$PR" ]] && rc=1
  return $rc
}

# clean up everything oc cluster up creates
oc_clean () {
  ${oc} cluster down "$UR"
  sleep 10

  local U="`mount | grep "^tmpfs on ${WD}/openshift.local.volumes/" | cut -d' ' -f3`"
  [[ -n "$U" ]] && echo "$U" | xargs sudo umount

  [[ "$WD" == "$PWD" ]] || exit 1
  sudo rm -rf *
  sudo rm -rf ~/.kube/
}

oc="`which oc`"

[[ "$1" == "--pretend" ]] && {
  shift
  oc="echo ${oc}"
  PR=y
  :
} || {
  [[ "$1" == "--clean" ]] && {
    shift
    CL=y
  }
}

[[ "${1:0:1}" == '-' ]] && false "Invalid arg: $1"

WD="${1:-/tmp/clusterup}"
UR="${2:-https://127.0.0.1:8443}"
AR="${3:---insecure-skip-tls-verify}"

mkdir -p "$WD"
cd "$WD"

[[ -n "$CL" ]] && {
  oc_clean
  oc_clean
}

oc_login || {
  ${oc} cluster up \
    --base-dir="${WD}" \
    --public-hostname=127.0.0.1
  oc_login
}
