#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

LAUNCH_DIR="${KARMADA_DIR}/LaunchAgents"
mkdir -p "${LAUNCH_DIR}"

util::cmd_must_exist "yq"

replace_options=(
  --kubeconfig=${KARMADA_KUBECONFIG}
  --authentication-kubeconfig=${KARMADA_KUBECONFIG}
  --authorization-kubeconfig=${KARMADA_KUBECONFIG}
  --etcd-servers=https://127.0.0.1:${ETCD_PORT}
  --etcd-cafile=${CERT_DIR}/server-ca.crt
  --etcd-certfile=${CERT_DIR}/karmada.crt
  --etcd-keyfile=${CERT_DIR}/karmada.key
  --tls-cert-file=${CERT_DIR}/karmada.crt
  --tls-private-key-file=${CERT_DIR}/karmada.key
  --service-account-issuer=https://127.0.0.1:${KARMADA_APISERVER_SECURE_PORT}
  --service-account-key-file=${CERT_DIR}/karmada.key
  --service-account-signing-key-file=${CERT_DIR}/karmada.key
  --proxy-client-cert-file=${CERT_DIR}/front-proxy-client.crt
  --proxy-client-key-file=${CERT_DIR}/front-proxy-client.key
  --requestheader-client-ca-file=${CERT_DIR}/front-proxy-ca.crt
  --client-ca-file=${CERT_DIR}/server-ca.crt
  --scheduler-estimator-ca-file=${CERT_DIR}/server-ca.crt
  --scheduler-estimator-cert-file=${CERT_DIR}/karmada.crt
  --scheduler-estimator-key-file=${CERT_DIR}/karmada.key
  --cert-file=${CERT_DIR}/karmada.crt
  --key-file=${CERT_DIR}/karmada.key
  --trusted-ca-file=${CERT_DIR}/server-ca.crt
  --data-dir=${KARMADA_DIR}/etcd
  --cert-dir=${CERT_DIR}
  --cluster-signing-cert-file=${CERT_DIR}/server-ca.crt
  --cluster-signing-key-file=${CERT_DIR}/server-ca.key
  --root-ca-file=${CERT_DIR}/server-ca.crt
  --service-account-private-key-file=${CERT_DIR}/karmada.key
)

do_replace_options() {
  content=$(cat)
  for replace in "${replace_options[@]}"; do
    option=$(echo "$replace" | awk -F= '{print $1}')
    content=$(echo "${content}" | sed "s|${option}=.*|${replace}|g")
  done
  echo "${content}"
}

files=()
for file in "${KARMADA_REPO_DIR}"/artifacts/deploy/*; do
  if egrep "^kind: (Deployment$|StatefulSet$)" $file >/dev/null \
     && [[ "$(basename ${file%.*})" != "karmada-scheduler-estimator" ]] \
     && [[ "$(basename ${file%.*})" != "karmada-metrics-adapter" ]]; then
    files+=("${file}")
  fi
done

port=${PORT_START}
for file in "${files[@]}"; do
  ((port++))
  server=$(basename ${file%.*})
  echo Install "${server}" to "${LAUNCH_DIR}/com.github.karmada-io.karmada-etcd.plist"

  yq eval '.spec.template.spec.containers[0].command[]' "${file}" \
    | sed "1s|.*|${KARMADA_DIR}/bin/${server}|" \
    | sed "s|--metrics-bind-address=.*|--metrics-bind-address=:${port}|g" \
    | do_replace_options \
    > "${LAUNCH_DIR}/com.github.karmada-io.${server}.plist"
done

set_server_secure_port() {
  local file="${LAUNCH_DIR}/com.github.karmada-io.${1}.plist"
  local port=$2
  if grep "\--secure-port" "${file}" >/dev/null; then
    sed -i '' "s|--secure-port=.*|--secure-port=${port}|" "${file}"
  else
    echo "--secure-port=${port}" >> "${file}"
  fi
}

set_server_secure_port karmada-apiserver            ${KARMADA_APISERVER_SECURE_PORT}
set_server_secure_port karmada-aggregated-apiserver ${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}
set_server_secure_port karmada-search               ${KARMADA_SEARCH_SECURE_PORT}
set_server_secure_port karmada-webhook              ${KARMADA_WEBHOOK_SECURE_PORT}

sed -i '' -e "1s|.*|${KARMADA_DIR}/bin/etcd|" \
          -e "s|://.*:2380|://localhost:${ETCD_PEER_PORT}|" \
          -e "s|://.*:2379|://localhost:${ETCD_PORT}|" \
          "${LAUNCH_DIR}/com.github.karmada-io.karmada-etcd.plist"

sed -i '' -e "1s|.*|${KARMADA_DIR}/bin/kube-apiserver|" \
          "${LAUNCH_DIR}/com.github.karmada-io.karmada-apiserver.plist"

cat >> "${LAUNCH_DIR}/com.github.karmada-io.karmada-webhook.plist" <<EOF
--tls-cert-file-name=karmada.crt
--tls-private-key-file-name=karmada.key
EOF

for file in "${files[@]}"; do
  server=$(basename ${file%.*})

  plist_file="${LAUNCH_DIR}/com.github.karmada-io.${server}.plist"
  cmd=$(cat "${plist_file}" | while IFS= read -r line; do echo "        <string>$line</string>"; done)

  cat > "${plist_file}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.karmada-io.${server}</string>
    <key>ProgramArguments</key>
    <array>
${cmd}
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/${server}.error</string>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/${server}.log</string>
</dict>
</plist>
EOF
done

echo "Start servers..."
"${KARMADA_DIR}"/ctrl.sh start

util::wait_until ${KARMADA_DIR}/bin/kubectl --kubeconfig=${KARMADA_KUBECONFIG} version -o yaml > /dev/null
