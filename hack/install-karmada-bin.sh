#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

KARMADA_REPO=${KARMADA_REPO:-https://github.com/karmada-io/karmada}
KARMADA_VERSION=${KARMADA_VERSION:-v1.4.0}

repo_dir=$(mktemp -u)
cleanup() {
  rm -rf "${repo_dir}"
}
trap "cleanup" EXIT SIGINT

echo "Install Karmada from ${KARMADA_REPO} ${KARMADA_VERSION}"
git clone -b "${KARMADA_VERSION}" "${KARMADA_REPO}" "${repo_dir}"
cd "${repo_dir}"
make all

mkdir -p "${BIN_DIR}"
mv _output/bin/*/*/* "${BIN_DIR}"
