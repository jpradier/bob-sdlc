# Bob SDLC - Payment Processing Demo Project

A comprehensive demonstration project showcasing modern software development lifecycle practices, including a Spring Boot payment processing application with complete infrastructure as code, deployment automation, and CI/CD capabilities.

## 🎯 Project Overview

This repository contains a full-stack payment processing application with enterprise-grade infrastructure automation, demonstrating best practices in:

- **Application Development:** Java 21 + Spring Boot REST API with React frontend
- **Infrastructure as Code:** Terraform for GitHub secrets management
- **Configuration Management:** Ansible for automated deployment
- **Container Orchestration:** Kubernetes/OpenShift deployment manifests
- **Testing & Quality:** Integration tests with JaCoCo coverage reporting
- **DevOps:** Automated deployment scripts and CI/CD ready

## 📁 Repository Structure

```
bob-sdlc/
├── payment-app/                    # Main Spring Boot application
│   ├── src/                        # Application source code
│   ├── infra/                      # Infrastructure as Code
│   │   ├── terraform/              # Terraform configurations
│   │   └── ansible/                # Ansible playbooks
│   ├── k8s/                        # Kubernetes manifests
│   ├── Dockerfile                  # Container image definition
│   ├── deploy-openshift.sh         # OpenShift deployment script
│   └── README.md                   # Detailed app documentation
├── PaymentApiIntegrationTestCoverageReport.md
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

- **Java 21** or higher
- **Maven 3.9+**
- **Docker** (for containerization)
- **Terraform** (for infrastructure provisioning)
- **Ansible** (for configuration management)
- **kubectl/oc** (for Kubernetes/OpenShift deployment)

### Run Locally

```bash
cd payment-app
mvn spring-boot:run
```

Access the application at: http://localhost:8080

### Run with Docker

```bash
cd payment-app
docker build -t payment-app:latest .
docker run -p 8080:8080 payment-app:latest
```

## 💳 Payment Application

A mock credit card payment processing system with:

- **REST API** for authorize, capture, and refund operations
- **React Frontend** with transaction history dashboard
- **In-memory H2 Database** (no external dependencies)
- **Caffeine Cache** for performance optimization
- **Actuator Endpoints** for health checks and metrics

### Key Features

- ✅ Card authorization with realistic processing delays
- ✅ Transaction capture and refund workflows
- ✅ Transaction history with status tracking
- ✅ Test card numbers for development
- ✅ Prometheus metrics integration
- ✅ Health check endpoints

**📖 [View Detailed Application Documentation](payment-app/README.md)**

## 🏗️ Infrastructure as Code

### Terraform

Located in [`payment-app/infra/terraform/`](payment-app/infra/terraform/)

Manages GitHub repository secrets for secure credential storage:

```bash
cd payment-app/infra/terraform
terraform init
terraform plan
terraform apply
```

**Features:**
- GitHub secrets management
- Environment variable configuration
- Secure credential handling

**📖 [View Terraform Documentation](payment-app/infra/terraform/README.md)**

### Ansible

Located in [`payment-app/infra/ansible/`](payment-app/infra/ansible/)

Automates application deployment and configuration:

```bash
cd payment-app/infra/ansible
ansible-playbook -i inventory/hosts.yml playbook.yml
```

**Features:**
- Automated deployment workflows
- Configuration management
- Multi-environment support

**📖 [View Ansible Documentation](payment-app/infra/ansible/README.md)**

## ☸️ Kubernetes/OpenShift Deployment

### Kubernetes

```bash
kubectl apply -f payment-app/k8s/deployment.yaml
```

### OpenShift

```bash
cd payment-app
./deploy-openshift.sh
```

**Deployment includes:**
- 3-replica deployment with auto-scaling (3-10 pods)
- Resource limits and requests
- Liveness and readiness probes
- HTTPS route with edge termination
- Pod disruption budget
- Horizontal pod autoscaler

## 🧪 Testing & Quality

### Run Tests

```bash
cd payment-app
mvn test
```

### Generate Coverage Report

```bash
mvn clean test jacoco:report
```

Coverage reports are available at: `payment-app/target/site/jacoco/index.html`

**📊 [View Test Coverage Report](PaymentApiIntegrationTestCoverageReport.md)**

## 📊 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payments/authorize` | Authorize a payment |
| POST | `/api/payments/capture` | Capture authorized payment |
| POST | `/api/payments/refund` | Refund captured payment |
| GET | `/api/payments/{id}` | Get transaction status |
| GET | `/api/payments/history` | List recent transactions |
| POST | `/admin/cache/clear` | Clear application cache |
| GET | `/actuator/health` | Health check |
| GET | `/actuator/prometheus` | Prometheus metrics |

## 🛠️ Technology Stack

### Application
- **Language:** Java 21
- **Framework:** Spring Boot 3.2.5
- **Database:** H2 (in-memory)
- **Cache:** Caffeine
- **Frontend:** React 18
- **Build:** Maven 3.9

### Infrastructure
- **IaC:** Terraform
- **Config Mgmt:** Ansible
- **Containers:** Docker + Distroless base
- **Orchestration:** Kubernetes/OpenShift

### DevOps
- **Testing:** JUnit 5, Spring Boot Test
- **Coverage:** JaCoCo
- **Monitoring:** Spring Actuator, Prometheus
- **CI/CD Ready:** GitHub Actions compatible

## 🔒 Security Features

- HTTPS/TLS support
- Secure credential management via Terraform
- Container security with distroless images
- Resource limits and quotas
- Health probes for reliability

## 📈 Monitoring & Observability

- **Health Checks:** `/actuator/health`
- **Metrics:** `/actuator/prometheus`
- **Cache Statistics:** Enabled via Caffeine
- **JVM Metrics:** Memory, GC, threads
- **HTTP Metrics:** Request counts, latencies

## 🚦 Getting Started Guide

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jpradier/bob-sdlc.git
   cd bob-sdlc
   ```

2. **Run the application:**
   ```bash
   cd payment-app
   mvn spring-boot:run
   ```

3. **Access the UI:**
   Open http://localhost:8080 in your browser

4. **Try the API:**
   ```bash
   curl -X POST http://localhost:8080/api/payments/authorize \
     -H "Content-Type: application/json" \
     -d '{"cardNumber":"4263970000005262","cardExpiry":"12/25","cvv":"123","amount":100.00}'
   ```

## 📚 Documentation

- **[Payment Application Guide](payment-app/README.md)** - Detailed application documentation
- **[Terraform Setup](payment-app/infra/terraform/README.md)** - Infrastructure provisioning
- **[Ansible Playbooks](payment-app/infra/ansible/README.md)** - Deployment automation
- **[IaC Architecture](payment-app/infra/IaCArchitecture.md)** - Infrastructure design
- **[Test Coverage Report](PaymentApiIntegrationTestCoverageReport.md)** - Quality metrics

## 🤝 Contributing

This is a demonstration project showcasing SDLC best practices. Feel free to explore, learn, and adapt for your own projects.

## 📝 License

This is a demo application for educational purposes.

## 🎓 Learning Objectives

This project demonstrates:

- ✅ Modern Java development with Spring Boot 3.x
- ✅ RESTful API design and implementation
- ✅ Frontend integration with React
- ✅ Infrastructure as Code with Terraform
- ✅ Configuration management with Ansible
- ✅ Container orchestration with Kubernetes/OpenShift
- ✅ Testing strategies and code coverage
- ✅ Monitoring and observability
- ✅ DevOps automation and CI/CD readiness
- ✅ Security best practices

---

**Built with ❤️ for demonstrating modern SDLC practices**# CI/CD Pipeline - Last updated: Wed May  6 20:38:35 CEST 2026
