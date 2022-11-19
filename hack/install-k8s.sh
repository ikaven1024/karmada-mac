#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

KUBE_REPO=${KUBE_REPO:-https://github.com/kubernetes/kubernetes.git}
KUBE_BRANCH=${KUBE_BRANCH:-release-1.23}

repo_dir=$(mktemp -u)
cleanup() {
  rm -rf "${repo_dir}"
}
trap "cleanup" EXIT SIGINT

echo "Install Kubernetes from ${KUBE_REPO} ${KUBE_BRANCH}"
git clone -b "${KUBE_BRANCH}" "${KUBE_REPO}" "${repo_dir}"
cd "${repo_dir}"
make kube-apiserver kube-controller-manager kubectl

mkdir -p "${BIN_DIR}"
mv _output/bin/{kube-apiserver,kube-controller-manager,kubectl} "${BIN_DIR}"
