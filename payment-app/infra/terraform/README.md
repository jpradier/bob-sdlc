# Payment Application - Terraform Infrastructure

This directory contains Terraform configuration to provision the complete OpenShift infrastructure and GitHub Actions secrets for the payment application.

## Overview

The Terraform configuration provisions:

- **Two OpenShift namespaces**: `bob-demo-staging` and `bob-demo-prod`
- **Per namespace**:
  - ResourceQuota (CPU/Memory limits)
  - NetworkPolicy (default-deny with specific allow rules)
  - ServiceAccount with least-privilege RBAC
  - PostgreSQL deployment with persistent storage (5Gi)
  - PostgreSQL ClusterIP service (port 5432, internal only)
- **GitHub Actions secrets** for CI/CD pipeline

## Architecture

Based on the infrastructure diagram in [`../IaCArchitecture.md`](../IaCArchitecture.md):

- Single OpenShift cluster with 5 worker nodes (16 vCPU, 64 GB RAM each)
- Separate PostgreSQL instance per namespace (no sharing)
- Network isolation: payment-service can only connect to postgres-service within the same namespace
- Internal image registry: `image-registry.openshift-image-registry.svc:5000`

## Files

| File | Description |
|------|-------------|
| [`provider.tf`](provider.tf) | Provider configuration (Kubernetes, GitHub, Null) |
| [`variables.tf`](variables.tf) | Input variables with descriptions and defaults |
| [`main.tf`](main.tf) | OpenShift infrastructure resources |
| [`github-secrets.tf`](github-secrets.tf) | GitHub Actions secrets configuration |
| [`outputs.tf`](outputs.tf) | Output values for reference |
| [`.env.example`](.env.example) | Environment variable template |

## Prerequisites

1. **Terraform** >= 1.0
2. **OpenShift CLI** (`oc`) - for obtaining cluster information
3. **OpenShift cluster access** with appropriate permissions
4. **GitHub Personal Access Token** with `repo` scope

## Setup

### 1. Configure Environment Variables

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` and provide values for all required variables:

```bash
# Required variables (no defaults)
TF_VAR_cluster_url=https://api.cluster-abc123.example.com:6443
TF_VAR_cluster_token=sha256~your-token-here
TF_VAR_github_token=ghp_your-github-token-here
TF_VAR_github_owner=your-org-or-username
TF_VAR_github_repository=payment-application
TF_VAR_openshift_server=https://api.cluster-abc123.example.com:6443
TF_VAR_openshift_token=sha256~your-token-here
TF_VAR_openshift_registry=default-route-openshift-image-registry.apps.cluster-abc123.example.com
```

### 2. Obtain OpenShift Information

#### Get Cluster URL
```bash
oc cluster-info | grep "Kubernetes control plane"
```

#### Get Service Account Token
```bash
# Create a service account (if needed)
oc create serviceaccount terraform-sa -n default

# Get the token
oc serviceaccounts get-token terraform-sa -n default
```

#### Get Internal Registry URL
```bash
oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}'
```

### 3. Load Environment Variables

```bash
export $(cat .env | xargs)
```

### 4. Initialize Terraform

```bash
terraform init
```

## Usage

### Plan Infrastructure Changes

```bash
terraform plan
```

### Apply Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

### View Outputs

```bash
terraform output
```

### Destroy Infrastructure

```bash
terraform destroy
```

**⚠️ WARNING**: This will delete all resources including PostgreSQL data!

## Provisioned Resources

### Per Namespace (Staging & Production)

#### Namespace
- Name: `bob-demo-staging` / `bob-demo-prod`
- Labels: `app.kubernetes.io/name=payment-application`, `app.kubernetes.io/environment=staging|prod`

#### ResourceQuota
- CPU Requests: 4 cores
- CPU Limits: 8 cores
- Memory Requests: 8Gi
- Memory Limits: 16Gi

#### NetworkPolicy
- **Default**: Deny all ingress/egress
- **Allow**: payment-service → postgres-service:5432
- **Allow**: payment-service → kube-dns:53 (DNS resolution)
- **Allow**: Ingress to payment-service from within namespace

#### ServiceAccount
- Name: `payment-service-sa`
- RBAC: Read-only access to ConfigMaps, Secrets, and Services

#### PostgreSQL
- **Deployment**: Single replica, postgres:15
- **Resources**: 500m-1 CPU, 1-2Gi memory
- **Storage**: 5Gi PersistentVolumeClaim
- **Service**: `postgres-service` on ClusterIP:5432 (internal only)
- **Health Checks**: Liveness and readiness probes

### GitHub Actions Secrets

Five secrets configured in the GitHub repository:

| Secret Name | Description |
|-------------|-------------|
| `OPENSHIFT_SERVER` | OpenShift cluster API URL |
| `OPENSHIFT_TOKEN` | Service account token for authentication |
| `OPENSHIFT_REGISTRY` | Internal image registry URL |
| `NAMESPACE_STAGING` | Staging namespace name |
| `NAMESPACE_PROD` | Production namespace name |

## Outputs

After applying, Terraform outputs the following information:

```bash
# Namespace names
namespace_staging = "bob-demo-staging"
namespace_prod = "bob-demo-prod"

# PostgreSQL endpoints
postgres_service_staging = "postgres-service.bob-demo-staging.svc.cluster.local:5432"
postgres_service_prod = "postgres-service.bob-demo-prod.svc.cluster.local:5432"

# Service accounts
service_account_staging = "payment-service-sa"
service_account_prod = "payment-service-sa"

# GitHub secrets
github_secrets_configured = [
  "OPENSHIFT_SERVER",
  "OPENSHIFT_TOKEN",
  "OPENSHIFT_REGISTRY",
  "NAMESPACE_STAGING",
  "NAMESPACE_PROD"
]
```

## Network Isolation

Each namespace is completely isolated:

- PostgreSQL services are internal-only (ClusterIP)
- Default-deny NetworkPolicy blocks all traffic
- Only payment-service can connect to postgres-service within the same namespace
- No cross-namespace communication allowed
- DNS resolution allowed for service discovery

## Security Considerations

1. **No Hardcoded Secrets**: All sensitive values supplied via environment variables
2. **Least-Privilege RBAC**: ServiceAccounts have minimal required permissions
3. **Network Segmentation**: NetworkPolicies enforce strict traffic rules
4. **Separate Databases**: Each environment has its own PostgreSQL instance
5. **Token Rotation**: Regularly rotate OpenShift and GitHub tokens

## Troubleshooting

### Authentication Issues

```bash
# Verify cluster access
oc whoami
oc auth can-i create namespace

# Test service account token
oc whoami --token=$TF_VAR_cluster_token
```

### Network Policy Issues

```bash
# Check NetworkPolicy status
oc get networkpolicy -n bob-demo-staging
oc describe networkpolicy default-deny-all -n bob-demo-staging

# Test connectivity from payment-service pod
oc exec -it <payment-pod> -n bob-demo-staging -- nc -zv postgres-service 5432
```

### PostgreSQL Issues

```bash
# Check PostgreSQL pod status
oc get pods -n bob-demo-staging -l app=postgres
oc logs -f <postgres-pod> -n bob-demo-staging

# Check PVC status
oc get pvc -n bob-demo-staging
oc describe pvc postgres-pvc -n bob-demo-staging
```

### GitHub Secrets Issues

```bash
# Verify GitHub token permissions
curl -H "Authorization: token $TF_VAR_github_token" \
  https://api.github.com/repos/$TF_VAR_github_owner/$TF_VAR_github_repository

# List configured secrets (names only, values are encrypted)
curl -H "Authorization: token $TF_VAR_github_token" \
  https://api.github.com/repos/$TF_VAR_github_owner/$TF_VAR_github_repository/actions/secrets
```

## Maintenance

### Updating PostgreSQL Version

Edit [`variables.tf`](variables.tf):

```hcl
variable "postgres_image" {
  default = "postgres:16"  # Update version
}
```

Then apply:

```bash
terraform apply
```

### Scaling Resources

Edit [`variables.tf`](variables.tf) to adjust ResourceQuota or PostgreSQL resources:

```hcl
variable "resource_quota_cpu_limits" {
  default = "16"  # Increase CPU limit
}
```

### Adding New Namespaces

Edit [`main.tf`](main.tf) and add to `locals.namespaces`:

```hcl
locals {
  namespaces = {
    staging = var.namespace_staging
    prod    = var.namespace_prod
    dev     = "bob-demo-dev"  # Add new namespace
  }
}
```

## CI/CD Integration

The provisioned GitHub secrets are used by GitHub Actions workflows:

```yaml
- name: Login to OpenShift
  run: |
    oc login ${{ secrets.OPENSHIFT_SERVER }} --token=${{ secrets.OPENSHIFT_TOKEN }}

- name: Build and Push Image
  run: |
    docker build -t ${{ secrets.OPENSHIFT_REGISTRY }}/${{ secrets.NAMESPACE_STAGING }}/payment-service:latest .
    docker push ${{ secrets.OPENSHIFT_REGISTRY }}/${{ secrets.NAMESPACE_STAGING }}/payment-service:latest
```

## References

- [Infrastructure Architecture Diagram](../IaCArchitecture.md)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [OpenShift Documentation](https://docs.openshift.com/)