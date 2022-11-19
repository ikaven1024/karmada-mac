#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

# check before install
if [[ -d "${KARMADA_DIR}" ]]; then
  echo "${KARMADA_DIR} is existed. Delete it before install."
  exit 1
fi

# start install
"${REPO_ROOT}"/hack/install-etcd.sh
"${REPO_ROOT}"/hack/install-k8s.sh
"${REPO_ROOT}"/hack/install-karmada.sh
"${REPO_ROOT}"/hack/install-certs.sh
"${REPO_ROOT}"/hack/install-scripts.sh
"${REPO_ROOT}"/hack/setup.sh

# waiting healthy
for i in {1..60}; do
  echo "Waiting healthy..."
  if "${REPO_ROOT}"/hack/check.sh > /dev/null 2>&1; then
    break
  fi
  sleep 1
done
"${REPO_ROOT}"/hack/check.sh;

# install successfully
cat <<EOF
==========================================================
Local Karmada is running.

To start using your karmada, run:
     "${BIN_DIR}/kubectl" --kubeconfig "${KARMADA_KUBECONFIG}" get clusters
Or
     export KUBECONFIG=${KARMADA_KUBECONFIG}
     "${BIN_DIR}/kubectl" get clusters
EOF

