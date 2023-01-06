#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

# waiting healthy
for i in {1..60}; do
  echo "Waiting karmada ready..."
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
