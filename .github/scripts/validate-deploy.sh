#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

source "${SCRIPT_DIR}/validation-functions.sh"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "operators" "turbo" "operator.yaml"
validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "xl-release.yaml"

check_k8s_namespace "${NAMESPACE}"

check_k8s_resource "${NAMESPACE}" serviceaccount "t8c-operator"
check_k8s_resource "${NAMESPACE}" deployment "t8c-operator"
check_k8s_resource "${NAMESPACE}" xl "xl-release"

check_k8s_resource "${NAMESPACE}" deployment action-orchestrator
check_k8s_resource "${NAMESPACE}" deployment api
check_k8s_resource "${NAMESPACE}" deployment auth
check_k8s_resource "${NAMESPACE}" deployment clustermgr
check_k8s_resource "${NAMESPACE}" deployment consul
check_k8s_resource "${NAMESPACE}" deployment cost
check_k8s_resource "${NAMESPACE}" deployment db
check_k8s_resource "${NAMESPACE}" deployment group
check_k8s_resource "${NAMESPACE}" deployment history
check_k8s_resource "${NAMESPACE}" deployment kafka
check_k8s_resource "${NAMESPACE}" deployment kubeturbo
check_k8s_resource "${NAMESPACE}" deployment market
check_k8s_resource "${NAMESPACE}" deployment nginx
check_k8s_resource "${NAMESPACE}" deployment plan-orchestrator
check_k8s_resource "${NAMESPACE}" deployment repository
check_k8s_resource "${NAMESPACE}" deployment rsyslog
check_k8s_resource "${NAMESPACE}" deployment topology-processor
check_k8s_resource "${NAMESPACE}" deployment ui
check_k8s_resource "${NAMESPACE}" deployment zookeeper

cd ..
rm -rf .testrepo
