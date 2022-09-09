
resource local_file write_outputs {
  filename = "gitops-output.json"

  content = jsonencode({
    name        = module.gitops_turbo.name
    branch      = module.gitops_turbo.branch
    namespace   = module.gitops_turbo.namespace
    server_name = module.gitops_turbo.server_name
    layer       = module.gitops_turbo.layer
    layer_dir   = module.gitops_turbo.layer == "infrastructure" ? "1-infrastructure" : (module.gitops_turbo.layer == "services" ? "2-services" : "3-applications")
    type        = module.gitops_turbo.type
  })
}
