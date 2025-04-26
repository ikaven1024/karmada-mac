#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

if [[ -d "${KARMADA_REPO_DIR}" ]]; then
  echo "Install Karmada from ${KARMADA_REPO_DIR} ..."
  repo_dir="${KARMADA_REPO_DIR}"
else
  echo "Install Karmada from ${KARMADA_REPO} ${KARMADA_VERSION}"
  repo_dir="${REPO_ROOT}/repos/karmada-${KARMADA_VERSION}"
  git clone --depth 1 --branch "${KARMADA_VERSION}" "${KARMADA_REPO}" ${repo_dir}
fi

cd "${repo_dir}"
make all

echo "Install to ${KARMADA_BIN}"
mkdir -p "${KARMADA_BIN}"
cp _output/bin/*/*/* "${KARMADA_BIN}"
