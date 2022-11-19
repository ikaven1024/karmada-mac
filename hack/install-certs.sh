#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

CERT_DIR=${KARMADA_DIR}
CFSSL_VERSION="v1.5.0"
KARMADA_APISERVER_IP=127.0.0.1

util::cmd_must_exist "openssl"
util::cmd_must_exist_cfssl ${CFSSL_VERSION}

# create CA signers
echo Create certs in "${CERT_DIR}"
mkdir -p "${CERT_DIR}"
util::create_signing_certkey "" "${CERT_DIR}" server '"client auth","server auth"'
util::create_signing_certkey "" "${CERT_DIR}" front-proxy '"client auth","server auth"'

# signs a certificate
util::create_certkey "" "${CERT_DIR}" "server-ca" \
  karmada system:admin kubernetes.default.svc \
  "*.etcd.karmada-system.svc.cluster.local" \
  "*.karmada-system.svc.cluster.local" \
  "*.karmada-system.svc" \
  "localhost" \
  "127.0.0.1"

util::create_certkey "" "${CERT_DIR}" "front-proxy-ca" \
  front-proxy-client \
  front-proxy-client kubernetes.default.svc \
  "*.etcd.karmada-system.svc.cluster.local" \
  "*.karmada-system.svc.cluster.local" \
  "*.karmada-system.svc" \
  "localhost" \
  "127.0.0.1"

# write karmada api server config to kubeconfig file
util::append_client_kubeconfig "${KARMADA_KUBECONFIG}" \
      "${CERT_DIR}/karmada.crt" "${CERT_DIR}/karmada.key" \
      "${KARMADA_APISERVER_IP}" "${KARMADA_APISERVER_SECURE_PORT}" \
      karmada-apiserver

# must set current-context correctly, or kubernetes & karmada components can't connect to kube-apiserver
kubectl --kubeconfig "${KARMADA_KUBECONFIG}" config use-context karmada-apiserver
