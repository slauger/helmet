#!/bin/bash

echoerr() { printf "%s\n" "$*" >&2; }

set -euo pipefail

# find all helmfiles in the current directory and in the special helmfile.d directory
find_helmfiles() {
  shopt -s nullglob

  is_error=1
  for file in helmfile{.yml,.yaml}{,.gotmpl} helmfile.d/*{.yaml,.yml}{,.gotmpl}; do
    if [ ! -f "$file" ]; then
      continue
    fi
    echo "$file"
    is_error=0
  done
  return $is_error
}

# create a dynamic helmfile which sets kubeVersion and apiVersions based on the current cluster
create_versions_helmfile() {
  # get the kubernetes version
  kube_version="$(kubectl version -o json | yq e '.serverVersion.gitVersion')"

  # create a "apiVersions" list for the helmfile template
  api_versions="$(kubectl api-resources | awk 'NR==1{start=index($0, "APIVERSION")} NR>1{split(substr($0, start), c, " "); print "- " c[1] "/" c[3]}')"

  # create file with our dynamically read kubeVersion and apiVersions
  printf "kubeVersion: %s\napiVersions:\n%s\n" "$kube_version" "$api_versions"
}

# create a dummy helmfile, that includes all helmfiles found with our override file
create_base_helmfile() {
  echo "bases:"
  echo "- '$1'"
  find_helmfiles | while read -r file; do
    echo "- '${file}'"
  done
}

case ${1} in
  "init")
    echoerr "starting init"
    ;;

  "generate")
    if [ ! -z "${ARGOCD_ENV_HELMFILE_ENVIRONMENT:-}" ]; then
      export HELMFILE_ENVIRONMENT="${ARGOCD_ENV_HELMFILE_ENVIRONMENT}"
    fi

    echoerr "starting generate"

    # create a temporary file to hold our dynamic configuration
    override_file="$(mktemp "/tmp/helmfile-versions-XXXXXX.yaml")"
    trap 'rm -f "$override_file"' EXIT

    # create file with kubeVersion and apiVersions
    create_versions_helmfile > "$override_file"

    # process a dummy helmfile which first includes our dynamic configuration and then the actual helmfile
    # this method allows the actual helmfile to override kubeVersion and apiVersions if needed
    create_base_helmfile "$override_file" | helmfile template -f - --include-crds
    ;;

  "discover")
    # We have to print something to stdout and exit with 0 if we want to process this ArgoCD app
    # This command does exactly that: list all helmfiles and exit with 1 if none are found
    find_helmfiles
    ;;

  *)
    echoerr "invalid invocation"
    exit 1
    ;;
esac
