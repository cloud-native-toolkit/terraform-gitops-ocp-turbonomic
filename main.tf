locals {
  name          = "turboinst"
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  inst_dir      = "${local.yaml_dir}/instance"

  type          = "instances"
  layer         = "services"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
  service_account_name = "t8c-operator"
}

resource gitops_service_account sa {
  name          = local.service_account_name
  namespace     = var.namespace
  server_name   = var.server_name
  branch        = local.application_branch
  config        = yamlencode(var.gitops_config)
  credentials   = yamlencode(var.git_credentials)

  service_account_name = local.service_account_name

  cluster_scope = true
  sccs          = ["anyuid","privileged"]
  pull_secrets  = var.pullsecret_name != null && var.pullsecret_name != "" ? [var.pullsecret_name] : []

  all_service_accounts = true

  rules {
    api_groups = [""]
    resources = ["configmaps","endpoints","events","persistentvolumeclaims","pods","secrets","serviceaccounts","services"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["apps"]
    resources = ["daemonsets","deployments","statefulsets","replicasets"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["apps"]
    resources = ["deployments/finalizers"]
    verbs = ["update"]
  }
  rules {
    api_groups = ["extensions"]
    resources = ["deployments"]
    verbs = ["*"]
  }
  rules {
    api_groups = [""]
    resources = ["namespaces"]
    verbs = ["get"]
  }
  rules {
    api_groups = ["policy"]
    resources = ["podsecuritypolicies","poddisruptionbudgets"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["rbac.authorization.k8s.io"]
    resources = ["clusterrolebindings","clusterroles","rolebindings","roles"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["batch"]
    resources = ["jobs"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["monitoring.coreos.com"]
    resources = ["servicemonitors"]
    verbs = ["get","create"]
  }
  rules {
    api_groups = ["charts.helm.k8s.io"]
    resources = ["*"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["networking.istio.io"]
    resources = ["gateways","virtualservices"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["cert-manager.io"]
    resources = ["certificates"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["route.openshift.io"]
    resources = ["routes","routes/custom-host"]
    verbs = ["*"]
  }
  rules {
    api_groups = ["security.openshift.io"]
    resource_names = ["turbonomic-t8c-operator-anyuid","turbonomic-t8c-operator-privileged"]
    resources = ["securitycontextconstraints"]
    verbs = ["use"]
  }
}

resource null_resource deploy_operator {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deployOp.sh '${local.yaml_dir}' '${gitops_service_account.sa.service_account_name}' '${gitops_service_account.sa.namespace}'"
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
    command = "${path.module}/scripts/deployInstance.sh '${local.inst_dir}' '${gitops_service_account.sa.service_account_name}' '${self.triggers.probes}' ${var.storage_class_name}"
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
