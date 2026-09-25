variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project_name" {
  type    = string
  default = "devops-lab"
}

variable "github_repo" {
  description = "GitHub repo allowed to deploy, in owner/name form (e.g. jdoe/devops-practice-lab)"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS version. Check the currently supported versions before applying."
  type        = string
  default     = "1.33"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "create_github_oidc_provider" {
  description = "Set false if your AWS account already has the GitHub OIDC provider (only one allowed per account)"
  type        = bool
  default     = true
}
