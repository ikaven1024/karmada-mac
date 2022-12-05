#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

ETCD_REPO=${ETCD_REPO:-https://github.com/etcd-io/etcd.git}
ETCD_VERSION=${ETCD_VERSION:-v3.5.3}

repo_dir=$(mktemp -u)
cleanup() {
  rm -rf "${repo_dir}"
}
trap "cleanup" EXIT SIGINT

echo "Install Etcd from ${ETCD_REPO} ${ETCD_VERSION}"
git clone -b "${ETCD_VERSION}" "${ETCD_REPO}" "${repo_dir}"
cd "${repo_dir}"
make

mkdir -p "${BIN_DIR}"
mv bin/{etcd,etcdctl} "${BIN_DIR}"
