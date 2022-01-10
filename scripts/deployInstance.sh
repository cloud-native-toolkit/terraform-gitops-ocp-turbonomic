#!/usr/bin/env bash

#SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
#CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

DEST_DIR="$1"
mkdir -p "${DEST_DIR}"

SANAME="$2"
#NAMESPACE="$3"
PROBES="$3"
STOR_NAME="$4"

cat > "${DEST_DIR}/xl-release.yaml" << EOL
apiVersion: charts.helm.k8s.io/v1
kind: Xl
metadata:
  name: xl-release
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  global:
    repository: turbonomic
    tag: 8.3.4
    externalArangoDBName: arango.turbo.svc.cluster.local
    storageClassName: ${STOR_NAME}
    serviceAccountName:  ${SANAME}

EOL


    if [[ "${PROBES}" =~ kubeturbo ]]; then
      echo "adding kubeturbo probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL

  kubeturbo:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ openshiftingress ]]; then
      echo "adding openshiftingress probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  openshiftingress:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ instana ]]; then
      echo "adding instana probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  instana:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ aws ]]; then
      echo "adding aws probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  aws:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ azure ]]; then
      echo "adding azure probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  azure:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ prometheus ]]; then
      echo "adding prometheus probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  prometheus:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ servicenow ]]; then
      echo "adding servicenow probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  servicenow:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ tomcat ]]; then
      echo "adding tomcat probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  tomcat:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ jvm ]]; then
      echo "adding jvm probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  jvm:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ websphere ]]; then
      echo "adding websphere probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  websphere:
    enabled: true
EOL
    fi

    if [[ "${PROBES}" =~ weblogic ]]; then
      echo "adding weblogic probe..."
      cat >> ${DEST_DIR}/xl-release.yaml << EOL
  
  weblogic:
    enabled: true
EOL
    fi

