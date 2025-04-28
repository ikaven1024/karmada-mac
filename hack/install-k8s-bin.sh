#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

if [[ -d "${KUBE_REPO_DIR}" ]]; then
  echo "Install Kubernetes from ${KUBE_REPO_DIR} ..."
else
  echo "Install Kubernetes from ${KUBE_REPO} ${KUBE_VERSION}"
  git clone --depth 1 --branch "${KUBE_VERSION}" "${KUBE_REPO}" "${KUBE_REPO_DIR}"
fi

cd "${KUBE_REPO_DIR}"
make kube-apiserver kube-controller-manager kube-scheduler kubectl

echo "Install to ${KARMADA_BIN}"
mkdir -p "${KARMADA_BIN}"
cp _output/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} "${KARMADA_BIN}"
