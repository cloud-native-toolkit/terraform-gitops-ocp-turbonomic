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
    apiGroups = [""]
    resources = ["configmaps","endpoints","events","persistentvolumeclaims","pods","secrets","serviceaccounts","services"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["apps"]
    resources = ["daemonsets","deployments","statefulsets","replicasets"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["apps"]
    resources = ["deployments/finalizers"]
    verbs = ["update"]
  }
  rules {
    apiGroups = ["extensions"]
    resources = ["deployments"]
    verbs = ["*"]
  }
  rules {
    apiGroups = [""]
    resources = ["namespaces"]
    verbs = ["get"]
  }
  rules {
    apiGroups = ["policy"]
    resources = ["podsecuritypolicies","poddisruptionbudgets"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["rbac.authorization.k8s.io"]
    resources = ["clusterrolebindings","clusterroles","rolebindings","roles"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["batch"]
    resources = ["jobs"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["monitoring.coreos.com"]
    resources = ["servicemonitors"]
    verbs = ["get","create"]
  }
  rules {
    apiGroups = ["charts.helm.k8s.io"]
    resources = ["*"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["networking.istio.io"]
    resources = ["gateways","virtualservices"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["cert-manager.io"]
    resources = ["certificates"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["route.openshift.io"]
    resources = ["routes","routes/custom-host"]
    verbs = ["*"]
  }
  rules {
    apiGroups = ["security.openshift.io"]
    resourceNames = ["turbonomic-t8c-operator-anyuid","turbonomic-t8c-operator-privileged"]
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
