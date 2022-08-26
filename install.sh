#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${ROOT_DIR}/util.sh"

source "${ROOT_DIR}/default.config"
[[ -f "${ROOT_DIR}/config" ]] && source "${ROOT_DIR}/config"

CERT_DIR=${KARMADA_DIR}
ROOT_CA_FILE=${CERT_DIR}/server-ca.crt
LAUNCH_DIR="${KARMADA_DIR}/LaunchAgents"
CFSSL_VERSION="v1.5.0"

KARMADA_APISERVER_IP=127.0.0.1

KUBECTL="kubectl --kubeconfig=${KARMADA_KUBECONFIG} --context karmada-apiserver"

install() {
  echo ! Starting install karmada
  print_binaries_version

  install_scripts
  gen_cert
  install_launch_tasks
  start

  util::wait_until ${KUBECTL} version -o yaml > /dev/null
  install_kube_artifacts

  print_success
}

uninstall() {
  "$KARMADA_DIR"/install.sh uninstall
}

start() {
  "$KARMADA_DIR"/install.sh start
}

stop() {
  "$KARMADA_DIR"/install.sh stop
}

restart() {
  "$KARMADA_DIR"/install.sh restart
}

status() {
  "$KARMADA_DIR"/install.sh status
}

help() {
  cat <<EOF
Usage: $0 <COMMAND>

Commands:
install   : install config files, and start karmada.
uninstall : stop karmada, and remove config files, and clean data.
start     : run the karmada.
stop      : stop the karmada.
status    : show the status of processes.
help      : print the usage of this script.
EOF
}

gen_cert() {
  if [[ ! -f "${CERT_DIR}"/karmada.key ]]; then
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
  fi

  # write karmada api server config to kubeconfig file
  util::append_client_kubeconfig "${KARMADA_KUBECONFIG}" \
	"${CERT_DIR}/karmada.crt" "${CERT_DIR}/karmada.key" \
	"${KARMADA_APISERVER_IP}" "${KARMADA_APISERVER_SECURE_PORT}" \
	karmada-apiserver
}

install_launch_tasks() {
  mkdir -p "${LAUNCH_DIR}"
  (
    cd "${ROOT_DIR}"/launch
    for file in *.plist; do
      echo !!! install launch task: "${file}"
      # shellcheck disable=SC2002
      cat "${file}" \
          | sed "s|{{BIN_DIR}}|${BIN_DIR}|g" \
          | sed "s|{{LOG_DIR}}|${LOG_DIR}|g" \
          | sed "s|{{KARMADA_DIR}}|${KARMADA_DIR}|g" \
          | sed "s|{{KARMADA_KUBECONFIG}}|${KARMADA_KUBECONFIG}|g" \
          | sed "s|{{ETCD_PORT}}|${ETCD_PORT}|g" \
          | sed "s|{{ETCD_PEER_PORT}}|${ETCD_PEER_PORT}|g" \
          | sed "s|{{KARMADA_APISERVER_SECURE_PORT}}|${KARMADA_APISERVER_SECURE_PORT}|g" \
          | sed "s|{{KARMADA_AGGREGATED_APISERVER_SECURE_PORT}}|${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}|g" \
          | sed "s|{{KARMADA_SEARCH_SECURE_PORT}}|${KARMADA_SEARCH_SECURE_PORT}|g" \
          | sed "s|{{KARMADA_WEBHOOK_SECURE_PORT}}|${KARMADA_WEBHOOK_SECURE_PORT}|g" \
          | sed "s|{{KARMADA_SCHEDULER_SECURE_PORT}}|${KARMADA_SCHEDULER_SECURE_PORT}|g" \
          | sed "s|{{KARMADA_CONTROLLER_MANAGER_SECURE_PORT}}|${KARMADA_CONTROLLER_MANAGER_SECURE_PORT}|g" \
          > "${LAUNCH_DIR}/${file}"
    done
  )
}

install_kube_artifacts() {
  echo !!! install kube artifacts
  local -r ca_string=$(base64 < "${ROOT_CA_FILE}" | tr "\n" " "|sed s/[[:space:]]//g)
  fill_caBundle() {
    sed "s/{{caBundle}}/${ca_string}/g" < "$1"
  }

  # create namespace for control plane components
  ${KUBECTL} apply -f "${ROOT_DIR}/artifacts/namespace.yaml"

  # deploy crds
  tmp_crds=$(mktemp -d)
  cp -rf "${ROOT_DIR}"/crds/* "${tmp_crds}"
  fill_caBundle "${ROOT_DIR}/crds/patches/webhook_in_resourcebindings.yaml" \
                   > "${tmp_crds}/patches/webhook_in_resourcebindings.yaml"
  fill_caBundle "${ROOT_DIR}/crds/patches/webhook_in_clusterresourcebindings.yaml" \
                   > "${tmp_crds}/patches/webhook_in_clusterresourcebindings.yaml"
  ${KUBECTL} apply -k "${tmp_crds}"
  rm -rf "${tmp_crds}"

  # deploy webhook configuration
  fill_caBundle "${ROOT_DIR}/artifacts/webhook-configuration.yaml" | ${KUBECTL} apply -f -

  # deploy APIService on karmada apiserver for karmada-aggregated-apiserver
  sed "s/{{KARMADA_AGGREGATED_APISERVER_SECURE_PORT}}/${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}/g" \
        "${ROOT_DIR}/artifacts/karmada-aggregated-apiserver-apiservice.yaml" \
        | ${KUBECTL} apply -f -

  # deploy APIService on karmada apiserver for karmada-search
  # shellcheck disable=SC2002
  sed "s/{{KARMADA_SEARCH_SECURE_PORT}}/${KARMADA_SEARCH_SECURE_PORT}/g" \
        "${ROOT_DIR}/artifacts/karmada-search-apiservice.yaml" \
        | ${KUBECTL} apply -f -

  # deploy cluster proxy rbac for admin
  ${KUBECTL} apply -f "${ROOT_DIR}/artifacts/cluster-proxy-admin-rbac.yaml"
}

install_scripts() {
  cp "$ROOT_DIR"/scripts/* "${KARMADA_DIR}"
}

print_binaries_version() {
  echo Install karmada with:
  "${BIN_DIR}"/etcd --version | grep etcd
  echo "karmada-apiserver version::: $("${BIN_DIR}"/kube-apiserver --version)"
  echo "kube-controller-manage version::r: $("${BIN_DIR}"/kube-controller-manager --version)"
  "${BIN_DIR}"/karmada-aggregated-apiserver version
  "${BIN_DIR}"/karmada-controller-manager version
  "${BIN_DIR}"/karmada-scheduler version
  "${BIN_DIR}"/karmada-descheduler version
  "${BIN_DIR}"/karmada-webhook version
  "${BIN_DIR}"/karmada-search version
  #  "${BIN_DIR}"/karmada-scheduler-estimator version
}

print_success() {
  cat <<EOF
==========================================================
Local Karmada is running.

To start using your karmada, run:
     ${KUBECTL} get clusters
Or
     export KUBECONFIG=${KARMADA_KUBECONFIG}
     kubectl config use-context karmada-apiserver
     kubectl get clusters
EOF
}

cmd=${1:-help}
case $cmd in
install|uninstall|start|stop|restart|status|help)
  $cmd
  ;;
*)
  echo unknown command "$cmd".
  help
  exit 1
esac
