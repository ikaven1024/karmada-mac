#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

echo "Install configs"
cp "${REPO_ROOT}/config.default" "${KARMADA_DIR}"
if [ -f "${REPO_ROOT}/config" ]; then
  cp "${REPO_ROOT}/config" "${KARMADA_DIR}"
fi

echo "Install scripts"
cp "${REPO_ROOT}"/scripts/* "${KARMADA_DIR}"
