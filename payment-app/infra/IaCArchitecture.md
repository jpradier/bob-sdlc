# Payment Application Infrastructure and Deployment Architecture

This diagram illustrates the complete infrastructure setup and CI/CD deployment flow for the payment application on OpenShift.

```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'fontSize':'14px'}}}%%
%% Payment Application Infrastructure Architecture
%% Version: 1.0
%% Last Updated: 2026-04-30
%% Description: Complete infrastructure setup and CI/CD deployment flow

graph LR

    %% ============================================
    %% OPENSHIFT CLUSTER INFRASTRUCTURE
    %% ============================================
    subgraph cluster["OpenShift Cluster"]
       direction BT
        %% Cluster-level Resources
        subgraph clusterResources["Cluster Resources"]
            direction LR
            WN1["🖥️ Worker Node 1<br/>16 vCPU, 64 GB RAM"]
            WN2["🖥️ Worker Node 2<br/>16 vCPU, 64 GB RAM"]
            WN3["🖥️ Worker Node 3<br/>16 vCPU, 64 GB RAM"]
            WN4["🖥️ Worker Node 4<br/>16 vCPU, 64 GB RAM"]
            WN5["🖥️ Worker Node 5<br/>16 vCPU, 64 GB RAM"]
            
            IR["📦 Internal Image Registry<br/>image-registry.openshift-<br/>image-registry.svc:5000"]
        end
        
        %% ============================================
        %% STAGING NAMESPACE
        %% ============================================
        subgraph stagingNS["🔧 bob-demo-staging Namespace"]
            direction TB
            
            %% Infrastructure as Code - Terraform
            subgraph stagingTF["Terraform - Infrastructure Layer"]
                STG_RQ["📊 ResourceQuota<br/>CPU/Memory Limits"]
                STG_NP["🔒 NetworkPolicy<br/>✅ Allow: payment-service → postgres:5432<br/>❌ Deny: all other ingress/egress"]
                STG_SA["👤 ServiceAccount<br/>Workload Identity"]
                STG_PVC["💾 PersistentVolumeClaim<br/>5Gi Storage"]
            end
            
            %% Configuration Management - Ansible
            subgraph stagingAnsible["Ansible - Configuration Layer"]
                STG_SECRET["🔐 Secret<br/>PostgreSQL Credentials"]
                STG_CM["⚙️ ConfigMap<br/>App Configuration"]
                STG_WAIT["⏳ PostgreSQL Readiness Wait<br/>+ Pre-flight Health Check"]
            end
            
            %% Application Workloads
            subgraph stagingWorkloads["Staging Workloads"]
                STG_PG["🗄️ PostgreSQL Deployment<br/>Port: 5432<br/>Replicas: 1"]
                STG_PG_SVC["🔌 postgres-service<br/>ClusterIP:5432<br/>Internal Only"]
                STG_APP["☕ payment-service<br/>Deployment<br/>Replicas: 2"]
            end
        end
        
        %% ============================================
        %% PRODUCTION NAMESPACE
        %% ============================================
        subgraph prodNS["🚀 bob-demo-prod Namespace"]
            direction TB
            
            %% Infrastructure as Code - Terraform
            subgraph prodTF["Terraform - Infrastructure Layer"]
                PROD_RQ["📊 ResourceQuota<br/>CPU/Memory Limits"]
                PROD_NP["🔒 NetworkPolicy<br/>✅ Allow: payment-service → postgres:5432<br/>❌ Deny: all other ingress/egress"]
                PROD_SA["👤 ServiceAccount<br/>Workload Identity"]
                PROD_PVC["💾 PersistentVolumeClaim<br/>5Gi Storage"]
            end
            
            %% Configuration Management - Ansible
            subgraph prodAnsible["Ansible - Configuration Layer"]
                PROD_SECRET["🔐 Secret<br/>PostgreSQL Credentials"]
                PROD_CM["⚙️ ConfigMap<br/>App Configuration"]
                PROD_WAIT["⏳ PostgreSQL Readiness Wait<br/>+ Pre-flight Health Check"]
            end
            
            %% Application Workloads
            subgraph prodWorkloads["Production Workloads"]
                PROD_PG["🗄️ PostgreSQL Deployment<br/>Port: 5432<br/>Replicas: 1"]
                PROD_PG_SVC["🔌 postgres-service<br/>ClusterIP:5432<br/>Internal Only"]
                PROD_APP["☕ payment-service<br/>Deployment<br/>Replicas: 3"]
            end
        end
    end
    
    %% ============================================
    %% CI/CD PIPELINE
    %% ============================================
    subgraph cicdPipeline["CI/CD Pipeline"]
        direction LR
        CI["🔨 CI Build<br/>Build Container Image<br/>GitHub Actions"]
        CD_STG["🚀 CD Auto-Deploy<br/>to Staging<br/>Automated"]
        PROMOTE["🏷️ Image Promotion<br/>oc tag within registry<br/>staging → production"]
        APPROVAL["✋ Manual Approval Gate<br/>Required for Production"]
        CD_PROD["🚀 CD Deploy<br/>to Production<br/>Manual Trigger"]
    end
    
    %% ============================================
    %% RELATIONSHIPS AND DEPENDENCIES
    %% ============================================
    
    %% Staging Infrastructure Dependencies
    STG_PVC -.-> STG_PG
    STG_SECRET -.-> STG_PG
    STG_SECRET -.-> STG_APP
    STG_CM -.-> STG_APP
    STG_WAIT -.-> STG_APP
    STG_PG --> STG_PG_SVC
    
    %% Production Infrastructure Dependencies
    PROD_PVC -.-> PROD_PG
    PROD_SECRET -.-> PROD_PG
    PROD_SECRET -.-> PROD_APP
    PROD_CM -.-> PROD_APP
    PROD_WAIT -.-> PROD_APP
    PROD_PG --> PROD_PG_SVC
    
    %% Network Policy Enforcement
    STG_NP -.-> STG_APP
    STG_NP -.-> STG_PG_SVC
    PROD_NP -.-> PROD_APP
    PROD_NP -.-> PROD_PG_SVC
    
    %% Application Database Connections
    STG_APP -->|"Connect<br/>Port 5432"| STG_PG_SVC
    PROD_APP -->|"Connect<br/>Port 5432"| PROD_PG_SVC
    
    %% CI/CD Deployment Flow
    CI -.->|"Push Image"| IR
    IR -.->|"Pull Image<br/>bob-demo-staging"| CD_STG
    CD_STG -.->|"Deploy"| STG_APP
    STG_APP -.->|"Success"| PROMOTE
    PROMOTE -.->|"Tag Image<br/>bob-demo-prod"| IR
    IR -.-> APPROVAL
    APPROVAL -.->|"Approved"| CD_PROD
    CD_PROD -.->|"Deploy"| PROD_APP
    
    %% ============================================
    %% STYLING AND VISUAL THEME
    %% ============================================
    
    %% Color Scheme:
    %% - Purple: Terraform (Infrastructure as Code)
    %% - Red: Ansible (Configuration Management)
    %% - Blue: Workloads (Running Applications)
    %% - Green: CI/CD (Automation Pipeline)
    %% - Orange: Registry (Image Storage)
    %% - Gold: Approval (Manual Gate)
    
    classDef terraform fill:#7B42BC,stroke:#5C2D91,stroke-width:2px,color:#fff,font-weight:bold
    classDef ansible fill:#EE0000,stroke:#CC0000,stroke-width:2px,color:#fff,font-weight:bold
    classDef workload fill:#0066CC,stroke:#004499,stroke-width:2px,color:#fff,font-weight:bold
    classDef cicd fill:#2E8B57,stroke:#1F6B3F,stroke-width:2px,color:#fff,font-weight:bold
    classDef registry fill:#FF6B35,stroke:#CC5529,stroke-width:2px,color:#fff,font-weight:bold
    classDef approval fill:#FFD700,stroke:#DAA520,stroke-width:3px,color:#000,font-weight:bold
    
    class STG_RQ,STG_NP,STG_SA,STG_PVC,PROD_RQ,PROD_NP,PROD_SA,PROD_PVC terraform
    class STG_SECRET,STG_CM,STG_WAIT,PROD_SECRET,PROD_CM,PROD_WAIT ansible
    class STG_PG,STG_PG_SVC,STG_APP,PROD_PG,PROD_PG_SVC,PROD_APP workload
    class CI,CD_STG,CD_PROD,PROMOTE cicd
    class IR registry
    class APPROVAL approval
```

## Architecture Overview

### Infrastructure Layer (Terraform)

**Cluster Configuration:**
- Single OpenShift cluster with 5 worker nodes
- Each worker node: 16 vCPU, 64 GB RAM
- Two namespaces: `bob-demo-staging` and `bob-demo-prod`

**Per Namespace Resources:**
- **ResourceQuota**: Limits resource consumption
- **NetworkPolicy**: 
  - Allows: `payment-service` → `postgres-service` on port 5432
  - Denies: All other ingress/egress by default
- **ServiceAccount**: Identity for workloads
- **PostgreSQL**:
  - Deployment with ClusterIP Service (port 5432, internal only)
  - PersistentVolumeClaim (5Gi) for data persistence

### Configuration Layer (Ansible)

**Per Namespace Configuration:**
- **Secret**: PostgreSQL credentials injection
- **ConfigMap**: Application configuration
- **Readiness Wait**: PostgreSQL readiness check before pre-flight health check

### CI/CD and Deployment Flow

1. **CI Build**: Builds container image from source code
2. **Image Push**: Pushes image to OpenShift internal registry (`image-registry.openshift-image-registry.svc:5000`)
3. **Auto-Deploy to Staging**: CD pipeline automatically deploys to `bob-demo-staging`
4. **Staging Validation**: `payment-service` connects to `postgres-service` in staging namespace
5. **Image Promotion**: Image promoted via `oc tag` within internal registry to `bob-demo-prod`
6. **Manual Approval**: Production deployment requires manual approval gate
7. **Production Deployment**: CD pipeline deploys to `bob-demo-prod`
8. **Production Runtime**: `payment-service` connects to its own `postgres-service` in production namespace

### Network Isolation

Each namespace maintains complete network isolation:
- Payment service can only communicate with PostgreSQL within the same namespace
- PostgreSQL services are internal-only (ClusterIP)
- NetworkPolicy enforces strict ingress/egress rules
- No cross-namespace communication allowed

### Image Registry Flow

- **Internal Registry**: `image-registry.openshift-image-registry.svc:5000`
- **Staging Image**: `bob-demo-staging/payment-service:latest`
- **Production Image**: Promoted via `oc tag` from staging to `bob-demo-prod/payment-service:latest`
- No external registry dependencies
