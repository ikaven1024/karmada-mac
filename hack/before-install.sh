#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

# check before install
if [[ -d "${KARMADA_DIR}" ]]; then
  echo "${KARMADA_DIR} is existed. Delete it before install."
  exit 1
fi
