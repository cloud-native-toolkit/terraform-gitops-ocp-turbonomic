locals {
  name          = "ocp-turbonomic"
  bin_dir       = module.setup_clis.bin_dir
  tmp_dir        = "${path.cwd}/.tmp/${local.name}"
  yaml_dir       = "${local.tmp_dir}/chart/${local.name}"

  layer              = "services"
  type               = "operators"
  application_branch = "main"
  layer_config       = var.gitops_config[local.layer]

  # set values content for subscription
  values_content = {
      turbo = {
        storagename = var.storage_class_name
        turbo_version = var.turbo_version
      }
    }
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = "t8c-operator"
  pull_secrets = var.pullsecret_name != null && var.pullsecret_name != "" ? [var.pullsecret_name] : []
  rbac_rules = [{
    apiGroups = [""]
    resources = ["configmaps","endpoints","events","persistentvolumeclaims","pods","secrets","serviceaccounts","services"]
    verbs = ["*"]
  },{
    apiGroups = ["apps"]
    resources = ["daemonsets","deployments","statefulsets","replicasets"]
    verbs = ["*"]
  },{
    apiGroups = ["apps"]
    resources = ["deployments/finalizers"]
    verbs = ["update"]
  },{
    apiGroups = ["extensions"]
    resources = ["deployments"]
    verbs = ["*"]
  },{
    apiGroups = [""]
    resources = ["namespaces"]
    verbs = ["get"]
  },{
    apiGroups = ["policy"]
    resources = ["podsecuritypolicies","poddisruptionbudgets"]
    verbs = ["*"]
  },{
    apiGroups = ["rbac.authorization.k8s.io"]
    resources = ["clusterrolebindings","clusterroles","rolebindings","roles"]
    verbs = ["*"]
  },{
    apiGroups = ["batch"]
    resources = ["jobs"]
    verbs = ["*"]
  },{
    apiGroups = ["monitoring.coreos.com"]
    resources = ["servicemonitors"]
    verbs = ["get","create"]
  },{
    apiGroups = ["charts.helm.k8s.io"]
    resources = ["*"]
    verbs = ["*"]
  },{
    apiGroups = ["networking.istio.io"]
    resources = ["gateways","virtualservices"]
    verbs = ["*"]
  },{
    apiGroups = ["cert-manager.io"]
    resources = ["certificates"]
    verbs = ["*"]
  },{
    apiGroups = ["route.openshift.io"]
    resources = ["routes","routes/custom-host"]
    verbs = ["*"]
  },{
    apiGroups = ["security.openshift.io"]
    resourceNames = ["turbonomic-t8c-operator-anyuid","turbonomic-t8c-operator-privileged"]
    resources = ["securitycontextconstraints"]
    verbs = ["use"]
  }
  ]
  sccs = ["anyuid","privileged"]
  server_name = var.server_name
  rbac_cluster_scope = true
}

module setup_group_scc {
  depends_on = [module.service_account]

  source = "github.com/cloud-native-toolkit/terraform-gitops-sccs.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  service_account = ""
  sccs = ["anyuid"]
  server_name = var.server_name
  group = true
}

# Add values for charts
resource "null_resource" "setup_gitops" {
  depends_on = [module.setup_group_scc]

  triggers = {
    probes = join(",", var.probes)
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}' '${self.triggers.probes}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

# Deploy
resource gitops_module turbomodule {
  depends_on = [null_resource.setup_gitops]

  name        = local.name
  namespace   = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

