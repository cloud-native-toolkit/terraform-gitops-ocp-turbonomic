locals {
  name          = "turbo"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  inst_dir      = "${local.yaml_dir}/instance"

  layer = "services"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
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

resource null_resource deploy_operator {
  depends_on = [module.setup_group_scc]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployOp.sh '${local.yaml_dir}' '${module.service_account.name}' '${var.namespace}'"
    
    environment = {
      BIN_DIR = local.bin_dir
    }
  }
}

resource null_resource setup_gitops_operator {
  depends_on = [null_resource.deploy_operator]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.name}' -n '${var.namespace}' --contentDir '${local.yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}' --debug"

    environment = {
      GIT_CREDENTIALS = yamlencode(nonsensitive(var.git_credentials))
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
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

resource null_resource setup_gitops_instance {
  depends_on = [null_resource.setup_gitops_operator,null_resource.deploy_instance]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module 'turboinst' -n '${var.namespace}' --contentDir '${local.inst_dir}' --serverName '${var.server_name}' -l '${local.layer}' --debug"

    environment = {
      GIT_CREDENTIALS = yamlencode(nonsensitive(var.git_credentials))
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}
