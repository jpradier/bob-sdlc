terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Kubernetes/OpenShift Provider Configuration
provider "kubernetes" {
  host  = var.cluster_url
  token = var.cluster_token

  # Skip TLS verification for self-signed certificates (adjust for production)
  insecure = true
}

# GitHub Provider Configuration
provider "github" {
  token = var.github_token
  owner = var.github_owner
}