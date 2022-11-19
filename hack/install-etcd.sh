#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

ETCD_REPO=${ETCD_REPO:-https://github.com/etcd-io/etcd.git}
ETCD_BRANCH=${ETCD_BRANCH:-release-3.5}

repo_dir=$(mktemp -u)
cleanup() {
  rm -rf "${repo_dir}"
}
trap "cleanup" EXIT SIGINT

echo "Install Etcd from ${ETCD_REPO} ${ETCD_BRANCH}"
git clone -b "${ETCD_BRANCH}" "${ETCD_REPO}" "${repo_dir}"
cd "${repo_dir}"
make

mkdir -p "${BIN_DIR}"
mv bin/{etcd,etcdctl} "${BIN_DIR}"
