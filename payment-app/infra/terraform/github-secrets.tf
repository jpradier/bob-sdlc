# ============================================================================
# GITHUB ACTIONS SECRETS
# ============================================================================

# OpenShift Server URL
resource "github_actions_secret" "openshift_server" {
  repository      = var.github_repository
  secret_name     = "OPENSHIFT_SERVER"
  plaintext_value = var.openshift_server
}

# OpenShift Authentication Token
resource "github_actions_secret" "openshift_token" {
  repository      = var.github_repository
  secret_name     = "OPENSHIFT_TOKEN"
  plaintext_value = var.openshift_token
}

# OpenShift Internal Image Registry
resource "github_actions_secret" "openshift_registry" {
  repository      = var.github_repository
  secret_name     = "OPENSHIFT_REGISTRY"
  plaintext_value = var.openshift_registry
}

# Staging Namespace
resource "github_actions_secret" "namespace_staging" {
  repository      = var.github_repository
  secret_name     = "NAMESPACE_STAGING"
  plaintext_value = var.namespace_staging
}

# Production Namespace
resource "github_actions_secret" "namespace_prod" {
  repository      = var.github_repository
  secret_name     = "NAMESPACE_PROD"
  plaintext_value = var.namespace_prod
}