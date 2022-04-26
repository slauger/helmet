#!/bin/bash

echoerr() { printf "%s\n" "$*" >&2; }

set -xe

if [[ -z "${1}" ]]; then
  echoerr "invalid invocation"
  exit 1
fi

PARAMS=" --allow-no-matching-release"

if [[ "${ARGOCD_APP_NAMESPACE}" ]]; then
  PARAMS+=" --namespace ${ARGOCD_APP_NAMESPACE}"
fi

export HOME="/tmp/helmfile/${ARGOCD_APP_NAME}"

mkdir -p "${HOME}"

case ${1} in
  "init")
    echoerr "starting init"
    helmfile repos
    ;;

  "generate")
    echoerr "starting generate"
    helmfile template
    ;;

  *)
    echoerr "invalid invocation"
    exit 1
    ;;
esac
