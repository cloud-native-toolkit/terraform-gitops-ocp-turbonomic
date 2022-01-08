#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
BRANCH="main"
SERVER_NAME="default"
TYPE="base"
LAYER="2-services"

COMPONENT_NAME="turbo"

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

#if [[ ! -f "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/xl.yaml" ]]; then
#  echo "Application values not found - payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/xl.yaml"
#  exit 1
#fi

#echo "Printing payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/xl.yaml"
#cat "payload/${LAYER}namespace/${NAMESPACE}/${COMPONENT_NAME}/xl.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi


### validation logic checks ####

#wait for deployment
sleep 8m

count=0
until kubectl rollout status deployment/t8c-operator -n "${NAMESPACE}" || [[ $count -eq 4 ]]; do
  echo "Waiting for turbo operator rollout to deploy"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 4 ]]; then
  echo "Timed out waiting for turbo operator to deploy"
  exit 1
fi


cd ..
rm -rf .testrepo
