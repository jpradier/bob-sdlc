# Local values for namespace configuration
locals {
  namespaces = {
    staging = var.namespace_staging
    prod    = var.namespace_prod
  }
}

# ============================================================================
# NAMESPACE RESOURCES
# ============================================================================

# Create Namespaces
resource "kubernetes_namespace" "payment_app" {
  for_each = local.namespaces

  metadata {
    name = each.value
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/name"        = "payment-application"
        "app.kubernetes.io/environment" = each.key
      }
    )
    annotations = {
      "description" = "Payment application ${each.key} environment"
    }
  }
}

# ============================================================================
# RESOURCE QUOTA
# ============================================================================

resource "kubernetes_resource_quota" "payment_app" {
  for_each = local.namespaces

  metadata {
    name      = "payment-app-quota"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_quota_cpu_requests
      "limits.cpu"      = var.resource_quota_cpu_limits
      "requests.memory" = var.resource_quota_memory_requests
      "limits.memory"   = var.resource_quota_memory_limits
    }
  }
}

# ============================================================================
# SERVICE ACCOUNT
# ============================================================================

resource "kubernetes_service_account" "payment_service" {
  for_each = local.namespaces

  metadata {
    name      = "payment-service-sa"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/component" = "service-account"
      }
    )
  }
}

# Role for payment service (least-privilege)
resource "kubernetes_role" "payment_service" {
  for_each = local.namespaces

  metadata {
    name      = "payment-service-role"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list"]
  }
}

# RoleBinding for payment service
resource "kubernetes_role_binding" "payment_service" {
  for_each = local.namespaces

  metadata {
    name      = "payment-service-rolebinding"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.payment_service[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.payment_service[each.key].metadata[0].name
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
  }
}

# ============================================================================
# NETWORK POLICY
# ============================================================================

# Default deny all ingress and egress
resource "kubernetes_network_policy" "default_deny" {
  for_each = local.namespaces

  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Allow payment-service to connect to postgres-service
resource "kubernetes_network_policy" "payment_to_postgres" {
  for_each = local.namespaces

  metadata {
    name      = "allow-payment-to-postgres"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "postgres"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "payment-service"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "5432"
      }
    }
  }
}

# Allow payment-service egress to postgres
resource "kubernetes_network_policy" "payment_egress" {
  for_each = local.namespaces

  metadata {
    name      = "allow-payment-egress"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "payment-service"
      }
    }

    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            "app" = "postgres"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "5432"
      }
    }

    # Allow DNS resolution
    egress {
      to {
        namespace_selector {
          match_labels = {
            "name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }
    }
  }
}

# Allow ingress to payment-service from within namespace
resource "kubernetes_network_policy" "payment_ingress" {
  for_each = local.namespaces

  metadata {
    name      = "allow-payment-ingress"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels    = var.common_labels
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "payment-service"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "name" = kubernetes_namespace.payment_app[each.key].metadata[0].name
          }
        }
      }
    }
  }
}

# ============================================================================
# POSTGRESQL - PERSISTENT VOLUME CLAIM
# ============================================================================

resource "kubernetes_persistent_volume_claim" "postgres" {
  for_each = local.namespaces

  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/component" = "database"
        "app"                         = "postgres"
      }
    )
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }

  wait_until_bound = false
}

# ============================================================================
# POSTGRESQL - DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "postgres" {
  for_each = local.namespaces

  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/component" = "database"
        "app"                         = "postgres"
      }
    )
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          "app"                         = "postgres"
          "app.kubernetes.io/component" = "database"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.postgres_image

          port {
            container_port = 5432
            name           = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = "paymentdb"
          }

          env {
            name  = "POSTGRES_USER"
            value = "paymentuser"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "changeme-${each.key}"
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          resources {
            limits = {
              cpu    = var.postgres_cpu_limit
              memory = var.postgres_memory_limit
            }
            requests = {
              cpu    = var.postgres_cpu_request
              memory = var.postgres_memory_request
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "paymentuser"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "paymentuser"]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres[each.key].metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.postgres
  ]
}

# ============================================================================
# POSTGRESQL - SERVICE
# ============================================================================

resource "kubernetes_service" "postgres" {
  for_each = local.namespaces

  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.payment_app[each.key].metadata[0].name
    labels = merge(
      var.common_labels,
      {
        "app.kubernetes.io/component" = "database"
        "app"                         = "postgres"
      }
    )
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app" = "postgres"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }

  depends_on = [
    kubernetes_deployment.postgres
  ]
}