#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

DEST_DIR="$1"
SANAME="$2"
NAMESP="$3"

mkdir -p "${DEST_DIR}"
echo "adding operator chart..."

#create operator
cat > "${DEST_DIR}/operator.yaml" << EOL
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/t8c-certified.turbonomic: ""
  name: t8c-certified
  namespace: ${NAMESP}
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  name: t8c-certified
  source: certified-operators
  sourceNamespace: openshift-marketplace
EOL

if [[  -f "${DEST_DIR}/operator.yaml" ]]; then
  echo "operator.yaml file found..."
fi
