#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")
KARMADA_REPO=${KARMADA_REPO:-"${ROOT_DIR}/../karmada"}
source "${KARMADA_REPO}/hack/util.sh"
source "${ROOT_DIR}/util.sh"

CFSSL_VERSION="v1.5.0"

KARMADA_DIR="${HOME}/.karmada"
BIN_DIR="${HOME}/bin"
LOG_DIR="${KARMADA_DIR}/logs"
CERT_DIR=${KARMADA_DIR}
ETCD_DIR=${KARMADA_DIR}/etcd
LAUNCH_DIR="${HOME}/Library/LaunchAgents"

ROOT_CA_FILE=${CERT_DIR}/server-ca.crt

KARMADA_KUBECONFIG=${KARMADA_KUBECONFIG:-"${KARMADA_DIR}/karmada-apiserver.config"}
KARMADA_APISERVER_IP=127.0.0.1
KARMADA_APISERVER_SECURE_PORT=5443

KUBECTL="kubectl --kubeconfig=${KARMADA_KUBECONFIG} --context karmada-apiserver"

install() {
  echo ! Starting install karmada

  echo install karmada with:
  "${BIN_DIR}"/etcd --version | grep etcd
  echo "kube-apiserver version::: $("${BIN_DIR}"/kube-apiserver --version)"
  echo "kube-controller-manage version::r: $("${BIN_DIR}"/kube-controller-manager --version)"
  "${BIN_DIR}"/karmada-aggregated-apiserver version
  "${BIN_DIR}"/karmada-controller-manager version
  "${BIN_DIR}"/karmada-scheduler version
  "${BIN_DIR}"/karmada-descheduler version
  "${BIN_DIR}"/karmada-webhook version
  "${BIN_DIR}"/karmada-search version
#  "${BIN_DIR}"/karmada-scheduler-estimator version

  gen_cert
  install_launch_tasks
  start

  util:wait_until ${KUBECTL} get ns > /dev/null

  install_kube_artifacts
}

uninstall() {
  echo ! Starting uninstall karmada
  stop
  uninstall_launch_tasks
  clean_dir
}

start() {
  (
    cd "${LAUNCH_DIR}"
    launchctl load com.github.karmada-io.*
  )
}

stop() {
  (
    cd "${LAUNCH_DIR}"
    launchctl unload com.github.karmada-io.*
  )
}

status() {
  launchctl list | grep -E "PID|com.github.karmada-io.*"
}

help() {
  cat <<EOF
Usage: $0 [start|stop|status|clean|help]
EOF
}

gen_cert() {
  if [[ -f "${CERT_DIR}"/tls.crt ]]; then
    echo !!! cert existed, skip.
    return
  fi

  echo !!! generate cert
  util::cmd_must_exist "openssl"
  util::cmd_must_exist_cfssl ${CFSSL_VERSION}

  # create CA signers
  rm -rf "${CERT_DIR}"
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

  # tls for webhook
  ln -s "${CERT_DIR}"/server-ca.key "${CERT_DIR}"/tls.key
  ln -s "${CERT_DIR}"/server-ca.crt "${CERT_DIR}"/tls.crt

  # write karmada api server config to kubeconfig file
  util::append_client_kubeconfig "${KARMADA_KUBECONFIG}" \
	"${CERT_DIR}/karmada.crt" "${CERT_DIR}/karmada.key" \
	"${KARMADA_APISERVER_IP}" "${KARMADA_APISERVER_SECURE_PORT}" \
	karmada-apiserver
  "${KUBECTL}" config use-context karmada-apiserver
}

install_launch_tasks() {
  (
    cd "${ROOT_DIR}"/launch
    for file in *.plist; do
      if [[ ! -f "${LAUNCH_DIR}/${file}" ]]; then
        echo !!! install launch task: "${file}"
        sed "s|{{HOME}}|${HOME}|g" < "${file}" > "${LAUNCH_DIR}/${file}"
      fi
    done
  )
}

uninstall_launch_tasks() {
  rm -rf "${LAUNCH_DIR}"/com.github.karmada-io.*.plist
}

install_kube_artifacts() {
  echo !!! install kube artifacts
  local -r ca_string=$(base64 < "${ROOT_CA_FILE}" | tr "\n" " "|sed s/[[:space:]]//g)
  fill_caBundle() {
    sed "s/{{caBundle}}/${ca_string}/g" < "$1"
  }

  # create namespace for control plane components
  ${KUBECTL} apply -f "${KARMADA_REPO}/artifacts/deploy/namespace.yaml"

  # deploy crds
  TEMP_PATH_CRDS=$(mktemp -d)
  cp -rf "${KARMADA_REPO}"/charts/karmada/_crds "${TEMP_PATH_CRDS}"
  fill_caBundle "${KARMADA_REPO}/charts/karmada/_crds/patches/webhook_in_resourcebindings.yaml" \
              > "${TEMP_PATH_CRDS}/_crds/patches/webhook_in_resourcebindings.yaml"
  fill_caBundle "${KARMADA_REPO}/charts/karmada/_crds/patches/webhook_in_resourcebindings.yaml" \
              > "${TEMP_PATH_CRDS}/_crds/patches/webhook_in_clusterresourcebindings.yaml"
  ${KUBECTL} kustomize "${TEMP_PATH_CRDS}"/_crds | ${KUBECTL} apply -f -
  rm -rf "${TEMP_PATH_CRDS}"

  # deploy webhook configuration
  fill_caBundle "${KARMADA_REPO}/artifacts/deploy/webhook-configuration.yaml" | ${KUBECTL} apply -f -

  # deploy APIService on karmada apiserver for karmada-aggregated-apiserver
  sed "s/karmada-aggregated-apiserver.karmada-system.svc.cluster.local/localhost/g" \
        "${KARMADA_REPO}/artifacts/deploy/karmada-aggregated-apiserver-apiservice.yaml" \
        | ${KUBECTL} apply -f -

  # deploy APIService on karmada apiserver for karmada-search
  # shellcheck disable=SC2002
  cat "${KARMADA_REPO}/artifacts/deploy/karmada-search-apiservice.yaml" \
        | sed "s/karmada-search.karmada-system.svc.cluster.local/localhost/g" \
        | sed '/    namespace: karmada-system/a\
    port: 6443
' \
        | ${KUBECTL} apply -f -

  # deploy cluster proxy rbac for admin
  ${KUBECTL} apply -f "${KARMADA_REPO}/artifacts/deploy/cluster-proxy-admin-rbac.yaml"
}

clean_dir() {
  echo !!! clean dir
#  rm -rf "${KARMADA_DIR}"
}

cmd=${1:-help}
case $cmd in
install|uninstall|start|stop|status|help)
  $cmd
  ;;
*)
  echo unknown command "$cmd".
  help
  exit 1
esac
