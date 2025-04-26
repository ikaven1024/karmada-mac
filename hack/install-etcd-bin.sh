#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

if [[ -n "${ETCD_DOWNLOAD_URL}" ]]; then
  echo "Install Etcd from ${ETCD_DOWNLOAD_URL}"
  download_dir=$(mktemp -d /tmp/XXXXXXXX)
  cleanup() {
    rm -rf "${download_dir}"
  }
  trap "cleanup" EXIT SIGINT

  curl -L "${ETCD_DOWNLOAD_URL}" | tar xz -C "${download_dir}"
  chmod +x ${download_dir}/etcd-*/{etcd,etcdctl,etcdutl}
  mkdir -p "${KARMADA_BIN}"
  cp ${download_dir}/etcd-*/{etcd,etcdctl,etcdutl} ${KARMADA_BIN}
  exit
fi

if [[ -d "${ETCD_REPO_DIR}" ]]; then
  echo "Install Etcd from ${ETCD_REPO_DIR}"
  repo_dir="${ETCD_REPO_DIR}"
else
  echo "Install Etcd from ${ETCD_REPO} ${ETCD_VERSION}"
  repo_dir="${REPO_ROOT}/repos/etcd-${ETCD_VERSION}"
  git clone --depth 1 --branch "${ETCD_VERSION}" "${ETCD_REPO}" "${repo_dir}"
fi

cd "${repo_dir}"
make

mkdir -p "${KARMADA_BIN}"
mv bin/{etcd,etcdctl,etcdutl} "${KARMADA_BIN}"
