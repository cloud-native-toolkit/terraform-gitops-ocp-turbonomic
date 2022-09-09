module "gitops_turbo_namespace" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-namespace.git?ref=provider"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  name = "turbonomic"
}

resource null_resource turbo_write_namespace {
  provisioner "local-exec" {
    command = "echo -n '${module.gitops_turbo_namespace.name}' > .namespace"
  }
}
