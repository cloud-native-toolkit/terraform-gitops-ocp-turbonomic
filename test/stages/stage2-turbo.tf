module "gitops_turbo" {
  depends_on = [module.gitops_turbo_namespace,module.gitops_storageclass]
  
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_turbo_namespace.name
  storage_class_name = module.gitops_storageclass.storage_name
  pullsecret_name = "dockerpull"
  probes = ["kubeturbo","ui"]
}
