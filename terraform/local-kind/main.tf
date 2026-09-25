terraform {
  required_version = ">= 1.6"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5"
    }
  }
}

provider "kind" {}

variable "cluster_name" {
  type    = string
  default = "devops-practice"
}

variable "host_port" {
  description = "Host port mapped to the NodePort (30080) used by the local overlay"
  type        = number
  default     = 8080
}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 30080
        host_port      = var.host_port
      }
    }

    node {
      role = "worker"
    }
  }
}

output "kubeconfig_path" {
  value = kind_cluster.this.kubeconfig_path
}

output "app_url" {
  value = "http://localhost:${var.host_port}"
}
