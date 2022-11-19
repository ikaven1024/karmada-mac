#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

LAUNCH_DIR="${KARMADA_DIR}/LaunchAgents"

echo "Install configs"
cp "$REPO_ROOT/default.config" "${KARMADA_DIR}"
if [ -f "$REPO_ROOT/config" ]; then
  cp "$REPO_ROOT/config" "${KARMADA_DIR}"
fi

echo "Install scripts"
cp "$REPO_ROOT"/scripts/* "${KARMADA_DIR}"

echo "Install tasks"
mkdir -p "${LAUNCH_DIR}"
for file in "${REPO_ROOT}"/launch/*.plist; do
  task_file=$(basename "$file")
  echo !!! Install launch task: "${task_file}"
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
      > "${LAUNCH_DIR}/${task_file}"
done
