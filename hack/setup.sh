#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

CERT_DIR=${KARMADA_DIR}
ROOT_CA_FILE=${CERT_DIR}/server-ca.crt
KUBECTL="${BIN_DIR}/kubectl --kubeconfig=${KARMADA_KUBECONFIG} --context karmada-apiserver"

"${REPO_ROOT}"/hack/ctrl.sh start
util::wait_until ${KUBECTL} version -o yaml > /dev/null

echo "Install artifacts"
ca_string=$(base64 < "${ROOT_CA_FILE}" | tr "\n" " "|sed s/[[:space:]]//g)
fill_caBundle() {
  sed "s/{{caBundle}}/${ca_string}/g" < "$1"
}

# create namespace for control plane components
${KUBECTL} apply -f "${REPO_ROOT}/artifacts/namespace.yaml"

# deploy crds
tmp_crds=$(mktemp -d)
cleanup() {
  rm -rf "${tmp_crds}"
}
trap "cleanup" EXIT SIGINT

cp -rf "${REPO_ROOT}"/crds/* "${tmp_crds}"
fill_caBundle "${REPO_ROOT}/crds/patches/webhook_in_resourcebindings.yaml" \
                 > "${tmp_crds}/patches/webhook_in_resourcebindings.yaml"
fill_caBundle "${REPO_ROOT}/crds/patches/webhook_in_clusterresourcebindings.yaml" \
                 > "${tmp_crds}/patches/webhook_in_clusterresourcebindings.yaml"
${KUBECTL} apply -k "${tmp_crds}"

# deploy webhook configuration
fill_caBundle "${REPO_ROOT}/artifacts/webhook-configuration.yaml" | ${KUBECTL} apply -f -

# deploy APIService on karmada apiserver for karmada-aggregated-apiserver
sed "s/{{KARMADA_AGGREGATED_APISERVER_SECURE_PORT}}/${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}/g" \
      "${REPO_ROOT}/artifacts/karmada-aggregated-apiserver-apiservice.yaml" \
      | ${KUBECTL} apply -f -

# deploy APIService on karmada apiserver for karmada-search
# shellcheck disable=SC2002
sed "s/{{KARMADA_SEARCH_SECURE_PORT}}/${KARMADA_SEARCH_SECURE_PORT}/g" \
      "${REPO_ROOT}/artifacts/karmada-search-apiservice.yaml" \
      | ${KUBECTL} apply -f -

# deploy cluster proxy rbac for admin
${KUBECTL} apply -f "${REPO_ROOT}/artifacts/cluster-proxy-admin-rbac.yaml"
