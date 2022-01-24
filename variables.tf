
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "probes" {
  description = "The probes to deploy with turbonomic"
  type        = list(string)
  default     = ["kubeturbo","instana","openshiftingress"]
}

variable "storage_class_name" {
  description = "Name of the block storage class to use - if multizone deployment then waitforfirstconsumer must be set on storageclass binding mode"
  type        = string
}

variable "namespace" {
  type        = string
  description = "Name of the existing namespace where turbo will be deployed."
  default     = "turbonomic"
}

variable "pullsecret_name" {
  type        = string
  description = "Name of the docker pull secret if needed - only needed if hitting docker rate limit"
  default     = ""
}

variable "repo_type" {
  type        = string
  description = "Pull Turbonomic images from RedHat Marketplace with value 'redhat' or docker with 'docker'"
  default     = "redhat"
}
