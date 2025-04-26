#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

DEPLOY_DIR="${KARMADA_DIR}/artifacts/deploy"
CRD_DIRS="${KARMADA_DIR}/artifacts/crds"
KUBECTL="${KARMADA_BIN}/kubectl --kubeconfig=${KARMADA_KUBECONFIG} --context karmada-apiserver"

echo "Install artifacts"
mkdir -p "${DEPLOY_DIR}" "${CRD_DIRS}"
cp "${KARMADA_REPO_DIR}/artifacts/deploy/namespace.yaml" \
   "${KARMADA_REPO_DIR}/artifacts/deploy/webhook-configuration.yaml" \
   "${KARMADA_REPO_DIR}/artifacts/deploy/karmada-aggregated-apiserver-apiservice.yaml" \
   "${KARMADA_REPO_DIR}/artifacts/deploy/karmada-search-apiservice.yaml" \
   "${KARMADA_REPO_DIR}/artifacts/deploy/admin-clusterrole-aggregation.yaml" \
   "${KARMADA_REPO_DIR}/artifacts/deploy/cluster-proxy-admin-rbac.yaml" \
   "${DEPLOY_DIR}"
cp -rf "${KARMADA_REPO_DIR}"/charts/karmada/_crds/* "${CRD_DIRS}"

ca_string=$(base64 < "${CERT_DIR}/server-ca.crt" | tr "\n" " "|sed s/[[:space:]]//g)
sed -i '' "s/{{caBundle}}/${ca_string}/g" "${CRD_DIRS}"/patches/*.yaml "${DEPLOY_DIR}"/*.yaml

sed -i '' -e "s|{{name}}.{{namespace}}.svc:443|localhost:${KARMADA_WEBHOOK_SECURE_PORT}|g" \
          "${CRD_DIRS}/patches/webhook_in_clusterresourcebindings.yaml"
sed -i '' -e "s|{{name}}.{{namespace}}.svc:443|localhost:${KARMADA_WEBHOOK_SECURE_PORT}|g" \
          "${CRD_DIRS}/patches/webhook_in_resourcebindings.yaml"
sed -i '' -e "s|karmada-webhook.karmada-system.svc:443|localhost:${KARMADA_WEBHOOK_SECURE_PORT}|g" \
          "${DEPLOY_DIR}/webhook-configuration.yaml"

modify_apiservice() {
  yq eval -i '
    select(.kind == "APIService").spec.service.port = '"${2}"' |
    select(.kind == "Service").spec.externalName = "localhost"
  ' "$1"
}
modify_apiservice "${DEPLOY_DIR}/karmada-aggregated-apiserver-apiservice.yaml" "${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}"
modify_apiservice "${DEPLOY_DIR}/karmada-search-apiservice.yaml"               "${KARMADA_SEARCH_SECURE_PORT}"

${KUBECTL} apply -f "${DEPLOY_DIR}"
${KUBECTL} apply -k "${CRD_DIRS}"
