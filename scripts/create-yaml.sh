#!/usr/bin/env bash

CHARTNAME="$1"
DEST_DIR="$2"
PROBES="$3"

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)
CHART_DIR=$(cd "${MODULE_DIR}/chart/${CHARTNAME}"; pwd -P)

mkdir -p "${DEST_DIR}"

## put the yaml resource content in DEST_DIR
cp -R "${CHART_DIR}"/* "${DEST_DIR}"

if [[ -n "${VALUES_CONTENT}" ]]; then
  echo "${VALUES_CONTENT}" > "${DEST_DIR}/values.yaml"
fi

cat >> ${DEST_DIR}/values.yaml << EOL
probes:
EOL

## add in probes as needed
    if [[ "${PROBES}" =~ kubeturbo ]]; then
      echo "adding kubeturbo probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  name: kubeturbo
EOL
    fi

    if [[ "${PROBES}" =~ instana ]]; then
      echo "adding instana probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: instana
EOL
    fi

    if [[ "${PROBES}" =~ aws ]]; then
      echo "adding aws probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: aws
EOL
    fi

    if [[ "${PROBES}" =~ azure ]]; then
      echo "adding azure probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: azure
EOL
    fi

    if [[ "${PROBES}" =~ prometheus ]]; then
      echo "adding prometheus probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: prometheus
EOL
    fi

    if [[ "${PROBES}" =~ servicenow ]]; then
      echo "adding servicenow probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: servicenow
EOL
    fi

    if [[ "${PROBES}" =~ tomcat ]]; then
      echo "adding tomcat probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: tomcat
EOL
    fi

    if [[ "${PROBES}" =~ jvm ]]; then
      echo "adding jvm probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: jvm
EOL
    fi

    if [[ "${PROBES}" =~ websphere ]]; then
      echo "adding websphere probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: websphere
EOL
    fi

    if [[ "${PROBES}" =~ weblogic ]]; then
      echo "adding weblogic probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: weblogic
EOL
    fi

    if [[ "${PROBES}" =~ ui ]]; then
      echo "adding ui probe..."
      cat >> ${DEST_DIR}/values.yaml << EOL
  
  name: ui
EOL
    fi
