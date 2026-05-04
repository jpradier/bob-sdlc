# ============================================================================
# NAMESPACE OUTPUTS
# ============================================================================

output "namespace_staging" {
  description = "Staging namespace name"
  value       = kubernetes_namespace.payment_app["staging"].metadata[0].name
}

output "namespace_prod" {
  description = "Production namespace name"
  value       = kubernetes_namespace.payment_app["prod"].metadata[0].name
}

# ============================================================================
# CLUSTER OUTPUTS
# ============================================================================

output "cluster_endpoint" {
  description = "OpenShift cluster API endpoint"
  value       = var.cluster_url
  sensitive   = true
}

# ============================================================================
# POSTGRESQL OUTPUTS - STAGING
# ============================================================================

output "postgres_service_staging" {
  description = "PostgreSQL service endpoint in staging namespace"
  value       = "${kubernetes_service.postgres["staging"].metadata[0].name}.${kubernetes_namespace.payment_app["staging"].metadata[0].name}.svc.cluster.local:5432"
}

output "postgres_cluster_ip_staging" {
  description = "PostgreSQL ClusterIP in staging namespace"
  value       = kubernetes_service.postgres["staging"].spec[0].cluster_ip
}

output "postgres_pvc_staging" {
  description = "PostgreSQL PVC name in staging namespace"
  value       = kubernetes_persistent_volume_claim.postgres["staging"].metadata[0].name
}

# ============================================================================
# POSTGRESQL OUTPUTS - PRODUCTION
# ============================================================================

output "postgres_service_prod" {
  description = "PostgreSQL service endpoint in production namespace"
  value       = "${kubernetes_service.postgres["prod"].metadata[0].name}.${kubernetes_namespace.payment_app["prod"].metadata[0].name}.svc.cluster.local:5432"
}

output "postgres_cluster_ip_prod" {
  description = "PostgreSQL ClusterIP in production namespace"
  value       = kubernetes_service.postgres["prod"].spec[0].cluster_ip
}

output "postgres_pvc_prod" {
  description = "PostgreSQL PVC name in production namespace"
  value       = kubernetes_persistent_volume_claim.postgres["prod"].metadata[0].name
}

# ============================================================================
# SERVICE ACCOUNT OUTPUTS
# ============================================================================

output "service_account_staging" {
  description = "Payment service ServiceAccount name in staging namespace"
  value       = kubernetes_service_account.payment_service["staging"].metadata[0].name
}

output "service_account_prod" {
  description = "Payment service ServiceAccount name in production namespace"
  value       = kubernetes_service_account.payment_service["prod"].metadata[0].name
}

# ============================================================================
# GITHUB SECRETS OUTPUTS
# ============================================================================

output "github_secrets_configured" {
  description = "List of GitHub Actions secrets that have been configured"
  value = [
    github_actions_secret.openshift_server.secret_name,
    github_actions_secret.openshift_token.secret_name,
    github_actions_secret.openshift_registry.secret_name,
    github_actions_secret.namespace_staging.secret_name,
    github_actions_secret.namespace_prod.secret_name
  ]
}

output "github_repository" {
  description = "GitHub repository where secrets are configured"
  value       = "${var.github_owner}/${var.github_repository}"
}

# ============================================================================
# RESOURCE SUMMARY
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of provisioned infrastructure"
  value = {
    cluster = {
      endpoint = var.cluster_url
    }
    namespaces = {
      staging = kubernetes_namespace.payment_app["staging"].metadata[0].name
      prod    = kubernetes_namespace.payment_app["prod"].metadata[0].name
    }
    postgres = {
      staging = {
        service    = kubernetes_service.postgres["staging"].metadata[0].name
        cluster_ip = kubernetes_service.postgres["staging"].spec[0].cluster_ip
        pvc        = kubernetes_persistent_volume_claim.postgres["staging"].metadata[0].name
      }
      prod = {
        service    = kubernetes_service.postgres["prod"].metadata[0].name
        cluster_ip = kubernetes_service.postgres["prod"].spec[0].cluster_ip
        pvc        = kubernetes_persistent_volume_claim.postgres["prod"].metadata[0].name
      }
    }
    service_accounts = {
      staging = kubernetes_service_account.payment_service["staging"].metadata[0].name
      prod    = kubernetes_service_account.payment_service["prod"].metadata[0].name
    }
    github_secrets = length([
      github_actions_secret.openshift_server.secret_name,
      github_actions_secret.openshift_token.secret_name,
      github_actions_secret.openshift_registry.secret_name,
      github_actions_secret.namespace_staging.secret_name,
      github_actions_secret.namespace_prod.secret_name
    ])
  }
  sensitive = true
}