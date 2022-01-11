#  Turbonomic Gitops terraform module
![Verify and release module](https://github.com/cloud-native-toolkit/terraform-gitops-ocp-turbonomic/workflows/Verify%20and%20release%20module/badge.svg)

Deploys Turbonomic operator into the cluster and creates an instance. By default, the kubeturbo probe is also installed into the cluster along with the OpenShift ingress.  Other probes to deploy can be specified in the probes variable, by default it will deploy:  turboprobe, openshift ingress, and instana.  The namespace to deploy within the cluster is defined in the variables, default is Turbonomic.  Also note if deploying on mzr cluster you'll need the custom storage created, default is true to create this automatically, if not mzr you can set to false and use another storage class you'd like.

### Supported Component Selector Probe Types 
Use these names in the `probes` variable to define additional probes as needed for your environment:
```
"kubeturbo","instana","openshiftingress", "aws", "azure", "prometheus", "servicenow", "tomcat", "jvm", "websphere", "weblogic"
```
## Supported platforms

- OCP 4.6+

## Module dependencies

The module uses the following elements

### Terraform providers

- helm - used to configure the scc for OpenShift
- null - used to run the shell scripts

### Environment

- kubectl - used to apply the yaml to create the route

## Suggested companion modules

The module itself requires some information from the cluster and needs a
namespace to be created. The following companion
modules can help provide the required information:

- Gitops - github.com/cloud-native-toolkit/terraform-tools-gitops
- Cluster - github.com/ibm-garage-cloud/terraform-cluster-ibmcloud
- Namespace - github.com/ibm-garage-cloud/terraform-cluster-namespace
- ArgoBootstrap - github.com/cloud-native-toolkit/terraform-tools-argocd-bootstrap
- SealedCert - github.com/cloud-native-toolkit/terraform-util-sealed-secret-cert
- ResourceGroup - github.com/cloud-native-toolkit/terraform-ibm-resource-group
- ServiceAccount - github.com/cloud-native-toolkit/terraform-gitops-service-account
- StorageClass - github.com/cloud-native-toolkit/terraform-gitops-ocp-storageclass


## Example usage

```hcl-terraform
module "turbonomic" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-ocp-turbonomic"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_turbo_namespace.name
  storage_class_name = module.gitops_storageclass.storage_name
  service_account_name = module.gitops_service_account.name

}
```
