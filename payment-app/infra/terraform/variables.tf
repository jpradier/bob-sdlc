# OpenShift Cluster Configuration
variable "cluster_url" {
  description = "OpenShift cluster API server URL (e.g., https://api.cluster.example.com:6443)"
  type        = string
  sensitive   = true
}

variable "cluster_token" {
  description = "Service account token for OpenShift authentication"
  type        = string
  sensitive   = true
}

# GitHub Configuration
variable "github_token" {
  description = "GitHub Personal Access Token with repo scope for managing secrets"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name (without owner prefix)"
  type        = string
}

# Namespace Configuration
variable "namespace_staging" {
  description = "Name of the staging namespace"
  type        = string
  default     = "bob-demo-staging"
}

variable "namespace_prod" {
  description = "Name of the production namespace"
  type        = string
  default     = "bob-demo-prod"
}

# ResourceQuota Configuration
variable "resource_quota_cpu_requests" {
  description = "CPU requests limit for ResourceQuota"
  type        = string
  default     = "4"
}

variable "resource_quota_cpu_limits" {
  description = "CPU limits for ResourceQuota"
  type        = string
  default     = "8"
}

variable "resource_quota_memory_requests" {
  description = "Memory requests limit for ResourceQuota"
  type        = string
  default     = "8Gi"
}

variable "resource_quota_memory_limits" {
  description = "Memory limits for ResourceQuota"
  type        = string
  default     = "16Gi"
}

# PostgreSQL Configuration
variable "postgres_image" {
  description = "PostgreSQL container image"
  type        = string
  default     = "postgres:15"
}

variable "postgres_storage_size" {
  description = "PostgreSQL PersistentVolumeClaim storage size"
  type        = string
  default     = "5Gi"
}

variable "postgres_cpu_limit" {
  description = "PostgreSQL CPU limit"
  type        = string
  default     = "1"
}

variable "postgres_memory_limit" {
  description = "PostgreSQL memory limit"
  type        = string
  default     = "2Gi"
}

variable "postgres_cpu_request" {
  description = "PostgreSQL CPU request"
  type        = string
  default     = "500m"
}

variable "postgres_memory_request" {
  description = "PostgreSQL memory request"
  type        = string
  default     = "1Gi"
}

# GitHub Actions Secrets Configuration
variable "openshift_server" {
  description = "OpenShift cluster API URL for GitHub Actions secrets"
  type        = string
  sensitive   = true
}

variable "openshift_token" {
  description = "Service account token for GitHub Actions secrets"
  type        = string
  sensitive   = true
}

variable "openshift_registry" {
  description = "OpenShift internal image registry URL (e.g., default-route-openshift-image-registry.apps.cluster.example.com)"
  type        = string
  sensitive   = true
}

# Common Labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "payment-application"
  }
}