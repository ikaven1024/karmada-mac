#!/usr/bin/env bash

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${ROOT_DIR}/default.config"
[[ -f "${ROOT_DIR}/config" ]] && source "${ROOT_DIR}/config"

# Some health check url is https, some is http.
readonly -A services_standard=(
  [karmada-aggregated-apiserver]="https://127.0.0.1:${KARMADA_AGGREGATED_APISERVER_SECURE_PORT}/livez?verbose"
  [karmada-controller-manager]="http://127.0.0.1:${KARMADA_CONTROLLER_MANAGER_SECURE_PORT}/healthz?verbose"
  [karmada-descheduler]="http://127.0.0.1:10358/healthz?verbose"
  [karmada-scheduler]="http://127.0.0.1:${KARMADA_SCHEDULER_SECURE_PORT}/healthz?verbose"
  [karmada-search]="https://127.0.0.1:${KARMADA_SEARCH_SECURE_PORT}/livez?verbose"
  [karmada-webhook]="https://127.0.0.1:${KARMADA_WEBHOOK_SECURE_PORT}/readyz/"
  [kube-apiserver]="https://127.0.0.1:${KARMADA_APISERVER_SECURE_PORT}/livez?verbose"
  [kube-controller-manager]="https://127.0.0.1:10257/healthz?verbose"
)

check_pass=1

declare -A check_results

# arg1: url
# arg2: additional options, may be empty string
# return: 0 if success, 1 if failed
# https://kubernetes.io/docs/reference/using-api/health-checks/
function health_check() {
  local http_code
  http_code="$(curl --silent $2 --output /dev/stderr --write-out "%{http_code}" \
    --cacert "${KARMADA_DIR}/server-ca.crt" \
    --cert "${KARMADA_DIR}/karmada.crt" \
    --key "${KARMADA_DIR}/karmada.key" \
    "$1")"
  test $? -eq '0' && test ${http_code} -eq '200'
  return $?
}

function check_all() {
  local key

  for key in "${!services_standard[@]}"
  do
    check_one "${key}" "${services_standard[${key}]}" ""
  done
}

# arg1: service name
# arg2: http url
# arg3: additional options, may be empty string
function check_one() {
  echo "###### Start check $1"
  health_check "$2" "$3"
  if [ $? -ne 0 ]
  then
    printf "\n###### $1 check failed\n\n\n"
    check_pass=0
    check_results[$1]="✘"
  else
    printf "\n###### $1 check success\n\n\n"
    check_results[$1]="✔"
  fi
}

function check_etcd() {
  echo "###### Start check etcd"
	etcdctl --cacert "${KARMADA_DIR}/server-ca.crt" \
    --cert "${KARMADA_DIR}/karmada.crt" \
    --key "${KARMADA_DIR}/karmada.key" \
    --endpoints "127.0.0.1:${ETCD_PORT}" \
    endpoint status --write-out="table"

  if [ $? -ne 0 ]
  then
    printf "\n###### etcd check failed\n\n\n"
    check_pass=0
    check_results[etcd]="✘"
  else
    printf "\n###### etcd check success\n\n\n"
    check_results[etcd]="✔"
  fi
}

function print_check_result() {
  echo "###### Summarized Health Check Result"

  local key
  for key in "${!check_results[@]}"
  do
    printf "${check_results[${key}]} ${key}\n"
  done

  printf "\n"
}

function main() {
  check_etcd
  check_all
  
  print_check_result

  [ ${check_pass} -eq 1 ]
  exit $?
}

main "$@"
