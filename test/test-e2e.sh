#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${TEST_DIR}/lib.sh"

BIN_DIR=${BIN_DIR:-"${HOME}/bin"}

ETCD_REPO=${ETCD_REPO:-https://github.com/etcd-io/etcd.git}
ETCD_BRANCH=${ETCD_BRANCH:-release-3.5}

KUBE_REPO=${KUBE_REPO:-https://github.com/kubernetes/kubernetes.git}
KUBE_BRANCH=${KUBE_BRANCH:-release-1.23}

KARMADA_REPO=${KARMADA_REPO:-https://github.com/karmada-io/karmada}
KARMADA_BRANCH=${KARMADA_BRANCH:-release-1.3}

mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:$PATH"

# Install Etcd binaries
(
  cd ~
  git clone -b "${ETCD_BRANCH}" "${ETCD_REPO}"
  cd "$(get_repo_name "${ETCD_REPO}")"
  make
  mv bin/{etcd,etcdctl} "${BIN_DIR}"
)

# Install Kubernetes binaries
(
  cd ~
  git clone -b "${KUBE_BRANCH}" "${KUBE_REPO}"
  cd "$(get_repo_name "${KUBE_REPO}")"
  make kube-apiserver kube-controller-manager kubectl
  mv _output/bin/{kube-apiserver,kube-controller-manager,kubectl} "${BIN_DIR}"
)

# Install Karmada binaries
(
  cd ~
  git clone -b "${KARMADA_BRANCH}" "${KARMADA_REPO}"
  cd "$(get_repo_name "${KARMADA_REPO}")"
  make all
  mv _output/bin/*/*/* "${BIN_DIR}"
)

# Install Karmada
./ctrl.sh install

# Check health
#cd ~/.karmada
#./health_check.sh
