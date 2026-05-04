# Payment Application - Ansible Configuration

This directory contains Ansible playbooks and roles to configure the OpenShift environment after Terraform provisioning.

## Overview

The Ansible configuration performs post-provisioning setup for both staging and production namespaces:

1. **Create PostgreSQL Credentials Secret** - Database connection details
2. **Create Application ConfigMap** - Application configuration
3. **Verify Service Account Permissions** - RBAC validation
4. **Wait for PostgreSQL Readiness** - Ensure database is ready
5. **Run Pre-flight Health Check** - Validate namespace readiness

## Architecture

Based on the infrastructure diagram in [`../IaCArchitecture.md`](../IaCArchitecture.md):

- Single OpenShift cluster with 5 worker nodes
- Two namespaces: `bob-demo-staging` and `bob-demo-prod`
- Separate PostgreSQL instance per namespace (provisioned by Terraform)
- No image pull secrets needed (internal registry auto-grants access)

## Files

| File | Description |
|------|-------------|
| [`playbook.yml`](playbook.yml) | Main playbook targeting both namespaces |
| [`inventory/hosts.yml`](inventory/hosts.yml) | OpenShift cluster inventory |
| [`roles/payment-app/tasks/main.yml`](roles/payment-app/tasks/main.yml) | Configuration tasks for each namespace |
| [`ansible.cfg`](ansible.cfg) | Ansible configuration settings |
| [`requirements.yml`](requirements.yml) | Required Ansible collections |

## Prerequisites

### 1. Software Requirements

- **Ansible** >= 2.14
- **Python** >= 3.8
- **OpenShift CLI** (`oc`)
- **Terraform** (infrastructure must be provisioned first)

### 2. Install Ansible Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

This installs:
- `kubernetes.core` - Kubernetes/OpenShift resource management
- `community.general` - Utility modules

### 3. OpenShift Authentication

Login to your OpenShift cluster:

```bash
oc login https://api.cluster.example.com:6443 --token=<your-token>
```

Verify access:

```bash
oc whoami
oc get namespaces
```

### 4. Environment Variables

Set the following environment variables (or update [`inventory/hosts.yml`](inventory/hosts.yml)):

```bash
export OPENSHIFT_SERVER="https://api.cluster.example.com:6443"
export OPENSHIFT_TOKEN="sha256~your-token-here"
export K8S_AUTH_VERIFY_SSL="no"  # For self-signed certificates
```

## Usage

### Run Complete Configuration

Configure both staging and production namespaces:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml
```

### Target Specific Namespace

Configure staging only:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --limit staging
```

Configure production only:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --limit prod
```

### Dry Run (Check Mode)

Preview changes without applying them:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --check
```

### Verbose Output

Run with increased verbosity:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml -v   # Verbose
ansible-playbook -i inventory/hosts.yml playbook.yml -vv  # More verbose
ansible-playbook -i inventory/hosts.yml playbook.yml -vvv # Debug
```

## Configuration Tasks

### 1. PostgreSQL Credentials Secret

Creates a Kubernetes Secret with database connection details:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: bob-demo-staging
type: Opaque
stringData:
  DB_URL: jdbc:postgresql://postgres-service:5432/paymentdb
  DB_USER: paymentuser
  DB_PASSWORD: changeme-staging
  POSTGRES_HOST: postgres-service
  POSTGRES_PORT: "5432"
  POSTGRES_DB: paymentdb
  POSTGRES_USER: paymentuser
  POSTGRES_PASSWORD: changeme-staging
```

### 2. Application ConfigMap

Creates a ConfigMap with application configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-app-config
  namespace: bob-demo-staging
data:
  SPRING_PROFILES_ACTIVE: staging
  LOG_LEVEL: DEBUG
  CACHE_TTL: "300"
  ENVIRONMENT: staging
  application.properties: |
    spring.application.name=payment-service
    spring.datasource.url=${DB_URL}
    # ... additional properties
```

### 3. Service Account Verification

Verifies that the service account and RBAC are properly configured:

- ServiceAccount: `payment-service-sa`
- Role: `payment-service-role`
- RoleBinding: `payment-service-rolebinding`

### 4. PostgreSQL Readiness Wait

Waits for PostgreSQL pod to be running and ready:

- Maximum wait time: 300 seconds (5 minutes)
- Retry interval: 10 seconds
- Checks pod phase and readiness conditions

### 5. Pre-flight Health Check

Validates all required resources exist:

- ✓ Secret: `postgres-credentials`
- ✓ ConfigMap: `payment-app-config`
- ✓ ServiceAccount: `payment-service-sa`
- ✓ Service: `postgres-service`
- ✓ NetworkPolicies configured
- ✓ PostgreSQL pod running and ready

## Namespace Configuration

### Staging Environment

```yaml
namespace: bob-demo-staging
environment: staging
db_password: changeme-staging
app_config:
  spring_profiles_active: staging
  log_level: DEBUG
  cache_ttl: "300"
```

### Production Environment

```yaml
namespace: bob-demo-prod
environment: prod
db_password: changeme-prod
app_config:
  spring_profiles_active: prod
  log_level: INFO
  cache_ttl: "600"
```

## Customization

### Modify Database Credentials

Edit [`playbook.yml`](playbook.yml) and update the `namespaces` variable:

```yaml
namespaces:
  - name: bob-demo-staging
    environment: staging
    db_password: "your-secure-password-here"
```

**⚠️ Security Note**: For production, use Ansible Vault to encrypt sensitive values:

```bash
ansible-vault encrypt_string 'your-secure-password' --name 'db_password'
```

### Modify Application Configuration

Edit the `app_config` section in [`playbook.yml`](playbook.yml):

```yaml
app_config:
  spring_profiles_active: "prod"
  log_level: "WARN"
  cache_ttl: "1200"
```

### Add Additional ConfigMap Data

Edit [`roles/payment-app/tasks/main.yml`](roles/payment-app/tasks/main.yml) and add to the ConfigMap data section:

```yaml
data:
  CUSTOM_SETTING: "value"
  FEATURE_FLAG: "enabled"
```

## Troubleshooting

### Authentication Issues

```bash
# Verify OpenShift login
oc whoami

# Check token validity
oc whoami --show-token

# Re-login if needed
oc login https://api.cluster.example.com:6443 --token=<token>
```

### Collection Not Found

```bash
# Install required collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general

# Verify installation
ansible-galaxy collection list
```

### PostgreSQL Not Ready

```bash
# Check PostgreSQL pod status
oc get pods -n bob-demo-staging -l app=postgres

# View PostgreSQL logs
oc logs -f <postgres-pod-name> -n bob-demo-staging

# Check PostgreSQL service
oc get svc postgres-service -n bob-demo-staging
```

### Secret/ConfigMap Issues

```bash
# List secrets
oc get secrets -n bob-demo-staging

# View secret details (base64 encoded)
oc get secret postgres-credentials -n bob-demo-staging -o yaml

# List ConfigMaps
oc get configmaps -n bob-demo-staging

# View ConfigMap details
oc get configmap payment-app-config -n bob-demo-staging -o yaml
```

### NetworkPolicy Issues

```bash
# List NetworkPolicies
oc get networkpolicy -n bob-demo-staging

# Describe NetworkPolicy
oc describe networkpolicy default-deny-all -n bob-demo-staging

# Test connectivity from a pod
oc run test-pod --image=busybox -n bob-demo-staging -- sleep 3600
oc exec -it test-pod -n bob-demo-staging -- nc -zv postgres-service 5432
```

## Integration with CI/CD

This Ansible playbook is designed to run after Terraform provisioning in a CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Provision Infrastructure
  run: |
    cd payment-app/infra/terraform
    terraform init
    terraform apply -auto-approve

- name: Configure Environment
  run: |
    cd payment-app/infra/ansible
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook -i inventory/hosts.yml playbook.yml
```

## Security Considerations

1. **Credentials Management**: Use Ansible Vault for sensitive data
2. **RBAC**: Service accounts have least-privilege permissions
3. **Network Isolation**: NetworkPolicies enforce strict traffic rules
4. **Secrets**: Kubernetes Secrets are used for sensitive configuration
5. **No Image Pull Secrets**: Internal registry auto-grants access within namespace

## Next Steps

After successful Ansible configuration:

1. **Deploy Application**: Use CI/CD pipeline to deploy payment-service
2. **Verify Connectivity**: Test application connection to PostgreSQL
3. **Run Integration Tests**: Execute application integration tests
4. **Monitor**: Set up monitoring and alerting

## References

- [Infrastructure Architecture Diagram](../IaCArchitecture.md)
- [Terraform Configuration](../terraform/README.md)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Core Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/)
- [OpenShift Documentation](https://docs.openshift.com/)