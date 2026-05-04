#!/usr/bin/env bash

################################################################################
# OpenShift Deployment Script for Payment Application
################################################################################
#
# DESCRIPTION:
#   This script deploys the payment-app Java application to OpenShift.
#   It verifies Java 21 is available, builds the application,
#   creates a container image, pushes it to OpenShift's internal registry,
#   and deploys the application to the specified namespace.
#
# PREREQUISITES:
#   - Java 21 installed and available in PATH
#   - OpenShift CLI (oc) installed and configured
#   - Docker or Podman installed
#   - Active OpenShift cluster connection (oc login completed)
#   - Sufficient permissions to create namespaces and deploy applications
#
# USAGE:
#   1. Make the script executable:
#      chmod +x deploy-openshift.sh
#
#   2. Run the script:
#      ./deploy-openshift.sh
#
#   3. Optional: Override default values with environment variables:
#      NAMESPACE=my-namespace IMAGE_TAG=v2.0.0 ./deploy-openshift.sh
#
# ENVIRONMENT VARIABLES:
#   NAMESPACE   - OpenShift namespace (default: deploy-test)
#   IMAGE_TAG   - Container image tag (default: latest)
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-deploy-test}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
APP_NAME="payment-app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

################################################################################
# Pre-flight Checks
################################################################################

log_info "Starting OpenShift deployment for ${APP_NAME}..."
log_info "Target namespace: ${NAMESPACE}"
log_info "Image tag: ${IMAGE_TAG}"

# Check required commands
log_info "Checking prerequisites..."
check_command oc || exit 1
if command -v docker &> /dev/null && docker info &> /dev/null; then
    CONTAINER_CMD="docker"
    log_success "Docker found"
elif command -v podman &> /dev/null && podman info &> /dev/null; then
    CONTAINER_CMD="podman"
    log_success "Podman found"
else
    if command -v docker &> /dev/null; then
        log_error "Docker CLI found but the daemon is not running."
        log_error "If you are using Colima, start it with: colima start"
    elif command -v podman &> /dev/null; then
        log_error "Podman CLI found but the daemon is not running."
        log_error "Start it with: podman machine start"
    else
        log_error "Neither Docker nor Podman found. Please install one of them."
    fi
    exit 1
fi

# Check OpenShift connection
if ! oc whoami &> /dev/null; then
    log_error "Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi
log_success "Connected to OpenShift as $(oc whoami)"

################################################################################
# Java Version Check
################################################################################

log_info "Checking Java installation..."

# Check if Java is installed
if ! check_command java; then
    log_error "Java is not installed or not in PATH"
    log_error "Please install Java 21 and ensure it's available in your PATH"
    exit 1
fi

# Get Java version
JAVA_VERSION_OUTPUT=$(java -version 2>&1 | head -n 1)
log_info "Found Java: ${JAVA_VERSION_OUTPUT}"

# Check if Java 21 is being used
if ! echo "${JAVA_VERSION_OUTPUT}" | grep -q "version \"21"; then
    log_warning "Java 21 is recommended for this application"
    log_warning "Current Java version: ${JAVA_VERSION_OUTPUT}"
    log_warning "Proceeding anyway, but build may fail if Java version is incompatible"
else
    log_success "Java 21 detected"
fi

################################################################################
# Build Application
################################################################################

log_info "Building application with Maven..."
cd "${SCRIPT_DIR}"

if [[ ! -f "pom.xml" ]]; then
    log_error "pom.xml not found in ${SCRIPT_DIR}"
    exit 1
fi

# Build the application (skip tests for faster deployment)
mvn clean package -DskipTests || {
    log_error "Maven build failed"
    exit 1
}
log_success "Application built successfully"

################################################################################
# OpenShift Namespace Setup
################################################################################

log_info "Setting up OpenShift namespace..."

# Create namespace if it doesn't exist
if ! oc get namespace "${NAMESPACE}" &> /dev/null; then
    log_info "Creating namespace ${NAMESPACE}..."
    oc create namespace "${NAMESPACE}"
    log_success "Namespace ${NAMESPACE} created"
else
    log_success "Namespace ${NAMESPACE} already exists"
fi

# Switch to the namespace
oc project "${NAMESPACE}"

################################################################################
# Container Registry Setup
################################################################################

log_info "Configuring OpenShift internal registry..."

# Try to get registry URL from route
REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}' 2>/dev/null || echo "")

# If route doesn't exist, try to create it
if [[ -z "${REGISTRY}" ]]; then
    log_warning "Default registry route not found, attempting to create it..."
    
    # Try to expose the registry service
    if oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}' 2>/dev/null; then
        log_info "Waiting for registry route to be created..."
        sleep 5
        REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}' 2>/dev/null || echo "")
    fi
fi

# If still no registry, use internal service as fallback
if [[ -z "${REGISTRY}" ]]; then
    log_warning "Could not create external route, using internal service..."
    
    # Check if image-registry service exists
    if oc get svc image-registry -n openshift-image-registry &>/dev/null; then
        REGISTRY="image-registry.openshift-image-registry.svc:5000"
        log_info "Using internal registry service: ${REGISTRY}"
    else
        log_error "Could not find image-registry service"
        log_error "Please ensure the image registry is properly configured:"
        log_error "  1. Check registry operator: oc get configs.imageregistry.operator.openshift.io/cluster"
        log_error "  2. Check registry service: oc get svc -n openshift-image-registry"
        log_error "  3. Expose route: oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{\"spec\":{\"defaultRoute\":true}}'"
        exit 1
    fi
fi

log_info "Registry URL: ${REGISTRY}"

# Resolve the active Docker daemon socket BEFORE overriding DOCKER_CONFIG.
# Docker stores context metadata inside $DOCKER_CONFIG/contexts/, so once DOCKER_CONFIG
# is redirected to a temp dir the named context (e.g. "colima") becomes unavailable.
# Capturing the socket as DOCKER_HOST pins build/push to the same daemon explicitly.
CURRENT_DOCKER_HOST=$(docker context inspect "$(docker context show)" \
    --format '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "")
if [[ -n "${CURRENT_DOCKER_HOST}" ]]; then
    log_info "Container daemon: ${CURRENT_DOCKER_HOST}"
fi

# Create a temporary Docker config directory.
# With no credsStore entry, docker login writes plain base64 credentials —
# bypassing the macOS keychain (osxkeychain / desktop credential store).
DOCKER_CONFIG_DIR=$(mktemp -d)
trap "rm -rf '${DOCKER_CONFIG_DIR}'" EXIT

# Wrapper: pin every container command to the same daemon socket and temp config.
run_container_cmd() {
    if [[ -n "${CURRENT_DOCKER_HOST}" ]]; then
        DOCKER_CONFIG="${DOCKER_CONFIG_DIR}" DOCKER_HOST="${CURRENT_DOCKER_HOST}" \
            "${CONTAINER_CMD}" "$@"
    else
        DOCKER_CONFIG="${DOCKER_CONFIG_DIR}" \
            "${CONTAINER_CMD}" "$@"
    fi
}

log_info "Logging into OpenShift registry..."
OC_TOKEN=$(oc whoami -t) || {
    log_error "Failed to retrieve OpenShift token"
    exit 1
}
# Use "unused" as username — oc whoami returns "kube:admin" which contains a colon
# and breaks Basic auth parsing (Basic auth splits on the first colon only).
# The OC bearer token carries all auth; the username value is irrelevant.
run_container_cmd login "${REGISTRY}" -u "unused" --password-stdin <<< "${OC_TOKEN}" || {
    log_error "Failed to login to OpenShift registry"
    exit 1
}
log_success "Logged into registry"

################################################################################
# Build and Push Container Image
################################################################################

IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${APP_NAME}:${IMAGE_TAG}"
log_info "Building container image: ${IMAGE_NAME}"

# Build image targeting linux/amd64 (OpenShift cluster is Linux)
run_container_cmd build \
    --platform linux/amd64 \
    -t "${IMAGE_NAME}" \
    -f Dockerfile \
    . || {
    log_error "Container image build failed"
    exit 1
}
log_success "Container image built"

# Push image to registry
log_info "Pushing image to OpenShift registry..."
run_container_cmd push "${IMAGE_NAME}" || {
    log_error "Failed to push image to registry"
    exit 1
}
log_success "Image pushed to registry"

################################################################################
# Deploy to OpenShift
################################################################################

log_info "Deploying application to OpenShift..."

# Process and apply Kubernetes manifests
if [[ -f "k8s/deployment.yaml" ]]; then
    log_info "Applying Kubernetes manifests..."
    
    # Replace environment variables in deployment.yaml
    export NAMESPACE IMAGE_TAG
    envsubst < k8s/deployment.yaml | oc apply -f - || {
        log_error "Failed to apply Kubernetes manifests"
        exit 1
    }
    log_success "Kubernetes manifests applied"
else
    log_warning "k8s/deployment.yaml not found, skipping manifest deployment"
fi

################################################################################
# Verify Deployment
################################################################################

log_info "Verifying deployment..."

# Wait for deployment to be ready
log_info "Waiting for deployment to be ready (timeout: 5 minutes)..."
oc rollout status deployment/${APP_NAME} -n "${NAMESPACE}" --timeout=5m || {
    log_error "Deployment failed or timed out"
    log_info "Check pod status with: oc get pods -n ${NAMESPACE}"
    log_info "Check logs with: oc logs -l app=${APP_NAME} -n ${NAMESPACE}"
    exit 1
}
log_success "Deployment is ready"

# Get route URL
ROUTE_URL=$(oc get route ${APP_NAME} -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [[ -n "${ROUTE_URL}" ]]; then
    log_success "Application is accessible at: https://${ROUTE_URL}"
else
    log_warning "No route found for application"
fi

################################################################################
# Summary
################################################################################

echo ""
log_success "=========================================="
log_success "Deployment completed successfully!"
log_success "=========================================="
echo ""
log_info "Namespace: ${NAMESPACE}"
log_info "Image: ${IMAGE_NAME}"
log_info "Application: ${APP_NAME}"
if [[ -n "${ROUTE_URL}" ]]; then
    log_info "URL: https://${ROUTE_URL}"
fi
echo ""
log_info "Useful commands:"
echo "  - View pods:        oc get pods -n ${NAMESPACE}"
echo "  - View logs:        oc logs -l app=${APP_NAME} -n ${NAMESPACE} -f"
echo "  - View deployment:  oc get deployment ${APP_NAME} -n ${NAMESPACE}"
echo "  - View route:       oc get route ${APP_NAME} -n ${NAMESPACE}"
echo "  - Scale app:        oc scale deployment/${APP_NAME} --replicas=5 -n ${NAMESPACE}"
echo ""

# Made with Bob
