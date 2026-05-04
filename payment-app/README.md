# Payment Processing Application

A mock credit card payment processing application built with Java 21, Spring Boot, and React.

## Features

### Backend (Java 21 + Spring Boot)
- **REST API Endpoints:**
  - `POST /api/payments/authorize` - Authorize a card transaction
  - `POST /api/payments/capture` - Capture an authorized transaction
  - `POST /api/payments/refund` - Refund a captured transaction
  - `GET /api/payments/{id}` - Get transaction status
  - `GET /api/payments/history` - List recent transactions (last 20)
  - `POST /admin/cache/clear` - Clear local cache
  - `GET /actuator/health` - Health check endpoint
  - `GET /actuator/prometheus` - Prometheus metrics

- **Technical Features:**
  - In-memory H2 database (no external DB required)
  - Caffeine cache for transaction lookups
  - Realistic processing delays (200-500ms)
  - Random transaction declines (10% rate)
  - Realistic response codes (approved, declined, insufficient funds, expired card)

### Frontend (React)
- Payment form with card number, expiry, CVV, and amount fields
- Transaction history dashboard
- Status badges: Authorized (yellow), Captured (green), Declined (red), Refunded (gray)
- One-click test card population
- Real-time transaction updates

### Test Cards
- **Visa:** 4263970000005262
- **MasterCard:** 5425230000004415
- **Amex:** 374101000000608

## Quick Start

### Prerequisites
- Java 21
- Maven 3.9+

### Run the Application

```bash
cd payment-app
mvn spring-boot:run
```

The application will start on `http://localhost:8080`

### Access the Application
- **Web UI:** http://localhost:8080
- **Health Check:** http://localhost:8080/actuator/health
- **Metrics:** http://localhost:8080/actuator/prometheus

## API Usage Examples

### Authorize a Payment
```bash
curl -X POST http://localhost:8080/api/payments/authorize \
  -H "Content-Type: application/json" \
  -d '{
    "cardNumber": "4263970000005262",
    "cardExpiry": "12/25",
    "cvv": "123",
    "amount": 100.00
  }'
```

### Capture an Authorized Transaction
```bash
curl -X POST http://localhost:8080/api/payments/capture \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "your-transaction-id"
  }'
```

### Refund a Captured Transaction
```bash
curl -X POST http://localhost:8080/api/payments/refund \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "your-transaction-id"
  }'
```

### Get Transaction Status
```bash
curl http://localhost:8080/api/payments/{transaction-id}
```

### Get Transaction History
```bash
curl http://localhost:8080/api/payments/history
```

### Clear Cache
```bash
curl -X POST http://localhost:8080/admin/cache/clear
```

## Docker Build

Build the Docker image:

```bash
docker build -t payment-app:latest .
```

Run the container:

```bash
docker run -p 8080:8080 payment-app:latest
```

## OpenShift Deployment

The application includes OpenShift deployment manifests with placeholder values.

### Deploy to OpenShift

1. **Set environment variables:**
```bash
export NAMESPACE=your-namespace
export IMAGE_TAG=v1.0.0
```

2. **Build and push image to OpenShift registry:**
```bash
# Login to OpenShift
oc login

# Create project if needed
oc new-project ${NAMESPACE}

# Build image
docker build -t payment-app:${IMAGE_TAG} .

# Tag for OpenShift registry
docker tag payment-app:${IMAGE_TAG} \
  image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/payment-app:${IMAGE_TAG}

# Push to registry
docker push image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/payment-app:${IMAGE_TAG}
```

3. **Deploy using the manifest:**
```bash
# Replace placeholders and apply
envsubst < k8s/deployment.yaml | oc apply -f -
```

### OpenShift Resources Created
- **Deployment:** 3 replicas with resource limits and health probes
- **Service:** ClusterIP service on port 8080
- **Route:** HTTPS route with edge termination
- **PodDisruptionBudget:** Max 1 unavailable pod
- **HorizontalPodAutoscaler:** Auto-scaling from 3 to 10 replicas

### Access the Application on OpenShift
```bash
# Get the route URL
oc get route payment-app -o jsonpath='{.spec.host}'
```

## Project Structure

```
payment-app/
├── src/
│   └── main/
│       ├── java/com/demo/payment/
│       │   ├── PaymentApplication.java
│       │   ├── controller/
│       │   │   ├── PaymentController.java
│       │   │   └── AdminController.java
│       │   ├── service/
│       │   │   └── PaymentService.java
│       │   ├── model/
│       │   │   ├── Transaction.java
│       │   │   ├── TransactionType.java
│       │   │   ├── TransactionStatus.java
│       │   │   ├── TransactionRepository.java
│       │   │   ├── PaymentRequest.java
│       │   │   └── PaymentResponse.java
│       │   └── config/
│       │       └── CacheConfig.java
│       └── resources/
│           ├── static/
│           │   └── index.html (React frontend)
│           └── application.properties
├── pom.xml
├── Dockerfile
├── k8s/
│   └── deployment.yaml
└── README.md
```

## Transaction Flow

1. **Authorize:** Client submits payment details → System validates card → Returns authorization
2. **Capture:** Client captures authorized transaction → Funds are captured
3. **Refund:** Client refunds captured transaction → Funds are returned

## Response Codes

- `APPROVED` - Transaction approved
- `DECLINED` - Transaction declined
- `INVALID_CARD` - Invalid card number
- `EXPIRED_CARD` - Card has expired
- `INSUFFICIENT_FUNDS` - Insufficient funds (random 10% decline)
- `CAPTURED` - Transaction captured successfully
- `REFUNDED` - Transaction refunded successfully

## Cache Configuration

- **Cache Provider:** Caffeine
- **Cache Name:** transactions
- **Max Size:** 1000 entries
- **TTL:** 10 minutes
- **Stats:** Enabled

## Monitoring

### Health Check
```bash
curl http://localhost:8080/actuator/health
```

### Prometheus Metrics
```bash
curl http://localhost:8080/actuator/prometheus
```

Available metrics include:
- JVM memory and GC metrics
- HTTP request metrics
- Cache statistics
- Custom application metrics

## Development Notes

### Lessons Learnt

1. **UUID Generation:** Spring Boot 3.x with JPA 3.x supports `GenerationType.UUID`. For compatibility, we use `@PrePersist` with `UUID.randomUUID()`.

2. **No Lombok:** To avoid annotation processing complexity and ensure portability, this project uses explicit getters/setters and hand-written builders instead of Lombok.

### Technology Stack

- **Java:** 21
- **Spring Boot:** 3.2.5
- **Database:** H2 (in-memory)
- **Cache:** Caffeine
- **Frontend:** React 18 (CDN)
- **Build Tool:** Maven 3.9
- **Container:** Distroless Java 21

## License

This is a demo application for educational purposes.