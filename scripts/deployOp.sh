#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

DEST_DIR="$1"
SANAME="$2"

mkdir -p "${DEST_DIR}"
echo "adding xl chart..."
#add chart to deployment directory
##cp "${CHART_DIR}/charts.helm.k8s.io_xls.yaml" "${DEST_DIR}/xl.yaml"

#create operator
cat > "${DEST_DIR}/operator.yaml" << EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t8c-operator
  labels:
    app.kubernetes.io/name: t8c-operator
    app.kubernetes.io/instance: t8c-operator
    app.kubernetes.io/managed-by: operator-life
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  replicas: 1
  selector:
    matchLabels:
      name: t8c-operator
  template:
    metadata:
      labels:
        name: t8c-operator
    spec:
      serviceAccountName: ${SANAME}
      containers:
      - name: t8c-operator
        image: turbonomic/t8c-operator:42.0
        imagePullPolicy: Always
        env:
        - name: WATCH_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: OPERATOR_NAME
          value: "t8c-operator"
        securityContext:
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL
        volumeMounts:
        - mountPath: /tmp
          name: operator-tmpfs0
      volumes:
      - name: operator-tmpfs0
        emptyDir: {}
EOL

if [[  -f "${DEST_DIR}/operator.yaml" ]]; then
  echo "operator.yaml file found..."
fi
