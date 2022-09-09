locals {
  name          = "turboinst"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  inst_dir      = "${local.yaml_dir}/instance"

  type          = "instance"
  layer         = "service"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git?ref=v1.16.9"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account?ref=v1.9.0"

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

  source = "github.com/cloud-native-toolkit/terraform-gitops-sccs.git?ref=v1.4.1"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  service_account = ""
  sccs = ["anyuid"]
  server_name = var.server_name
  group = true
}

resource null_resource deploy_operator {
  depends_on = [module.setup_group_scc]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployOp.sh '${local.yaml_dir}' '${module.service_account.name}' '${var.namespace}'"
    
    environment = {
      BIN_DIR = local.bin_dir
    }
  }
}

resource gitops_module operator {
  depends_on = [null_resource.deploy_operator]

  name = "turbo"
  namespace = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = "operators"
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

resource "null_resource" "deploy_instance" {
  depends_on = [null_resource.deploy_operator]
  triggers = {
    probes = join(",", var.probes)
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployInstance.sh '${local.inst_dir}' '${module.service_account.name}' '${self.triggers.probes}' ${var.storage_class_name}"

    environment = {
      BIN_DIR = local.bin_dir
    }
  }
}

resource gitops_module module {
  depends_on = [null_resource.deploy_instance]

  name = local.name
  namespace = var.namespace
  content_dir = local.inst_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
