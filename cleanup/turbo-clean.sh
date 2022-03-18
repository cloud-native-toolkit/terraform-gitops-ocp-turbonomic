#!/usr/bin/env bash

# takes one parameter the namespace where turbo is installed
NAMESPACE="$1"

#checks for only 1 param
if [ $# -eq 0 ]
  then
    echo "No arguments given. Please specify a namespace."
    exit 0
fi

##
## Turbonomic cleanup script to remove installed resources from gitops deployment
##

# remove argo apps 
kubectl delete application 0-bootstrap -n openshift-gitops
kubectl delete application 1-infrastructure -n openshift-gitops
kubectl delete application 2-services -n openshift-gitops
kubectl delete application 3-applications -n openshift-gitops
kubectl delete application namespace-turbonomic -n openshift-gitops
kubectl delete application turbonomic-t8c-operator-rbac -n openshift-gitops
kubectl delete application turbonomic-t8c-operator-sa -n openshift-gitops
kubectl delete application turbonomic-t8c-operator-scc -n openshift-gitops
kubectl delete application turbonomic-turbo -n openshift-gitops
kubectl delete application turbonomic-turboinst -n openshift-gitops
kubectl delete application turbonomic-turbonomic-group -n openshift-gitops

echo "cleaning up previous turbonomic install\n"
echo "removing xl-release..."
kubectl delete Xl xl-release -n ${NAMESPACE} >/dev/null 2>&1 &

# In the case that Kubernetes hangs on deleting the XL instance, set the finalizer to null which will force delete the XL instance this is a known issue with latest release
resp=$(kubectl get xl/xl-release -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)

if [[ "${resp}" != "0" ]]; then
    echo "patching instance..."
    kubectl patch xl/xl-release -p '{"metadata":{"finalizers":[]}}' --type=merge -n ${NAMESPACE} 2>/dev/null
fi

# remove chart and operator
kubectl delete crd xls.charts.helm.k8s.io
kubectl delete csv t8c-operator.v42.6.0 -n kubectl delete clusterrole


kubectl delete clusterrolebinding t8c-operator
kubectl delete clusterrolebinding turbo-all-binding

kubectl delete clusterrole t8c-operator
kubectl delete clusterrole turbonomic-operator-group-admin
kubectl delete clusterrole turbonomic-operator-group-edit
kubectl delete clusterrole turbonomic-operator-group-view

kubectl delete project ${NAMESPACE} 

# remove scc
kubectl delete scc ${NAMESPACE}-t8c-operator-anyuid
kubectl delete scc ${NAMESPACE}-t8c-operator-privileged
kubectl delete scc ${NAMESPACE}-anyuid
