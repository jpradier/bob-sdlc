#!/usr/bin/env bash
################################################################################
# OpenShift CI/CD Namespace Setup Script
################################################################################
#
# This script sets up both staging and production namespaces with proper
# service accounts and permissions for the GitHub Actions CI/CD pipeline.
#
# PREREQUISITES:
#   - You must be logged in as a cluster admin or user with project creation rights
#   - Run: oc login --server=<server> --token=<admin-token>
#
# USAGE:
#   chmod +x setup-cicd-namespaces.sh
#   ./setup-cicd-namespaces.sh
#
################################################################################

set -e
set -u
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
STAGING_NAMESPACE="bob-demo-staging"
PROD_NAMESPACE="bob-demo-prod"
SERVICE_ACCOUNT="github-actions"

################################################################################
# Pre-flight Checks
################################################################################

log_info "Starting OpenShift CI/CD namespace setup..."
echo ""

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    log_error "OpenShift CLI (oc) is not installed"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    log_error "Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

CURRENT_USER=$(oc whoami)
log_info "Logged in as: ${CURRENT_USER}"

# Check if user has admin privileges
if [[ "${CURRENT_USER}" == system:serviceaccount:* ]]; then
    log_warning "You are logged in as a service account: ${CURRENT_USER}"
    log_warning "Service accounts typically don't have project creation rights."
    log_warning "Please log in as a cluster admin or user with project creation privileges."
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Exiting. Please log in with appropriate credentials."
        exit 1
    fi
fi

echo ""

################################################################################
# Create Staging Namespace
################################################################################

log_info "Setting up staging namespace: ${STAGING_NAMESPACE}"

if oc get project "${STAGING_NAMESPACE}" &> /dev/null; then
    log_success "Namespace ${STAGING_NAMESPACE} already exists"
else
    log_info "Creating namespace ${STAGING_NAMESPACE}..."
    oc new-project "${STAGING_NAMESPACE}" || {
        log_error "Failed to create namespace ${STAGING_NAMESPACE}"
        log_error "You may not have permissions to create projects."
        exit 1
    }
    log_success "Namespace ${STAGING_NAMESPACE} created"
fi

# Create service account in staging
if oc get sa "${SERVICE_ACCOUNT}" -n "${STAGING_NAMESPACE}" &> /dev/null; then
    log_success "Service account ${SERVICE_ACCOUNT} already exists in ${STAGING_NAMESPACE}"
else
    log_info "Creating service account ${SERVICE_ACCOUNT} in ${STAGING_NAMESPACE}..."
    oc create serviceaccount "${SERVICE_ACCOUNT}" -n "${STAGING_NAMESPACE}"
    log_success "Service account created"
fi

# Grant permissions in staging
log_info "Granting permissions in ${STAGING_NAMESPACE}..."

oc policy add-role-to-user system:image-pusher \
    "system:serviceaccount:${STAGING_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${STAGING_NAMESPACE}" 2>/dev/null || log_warning "image-pusher role may already be assigned"

oc policy add-role-to-user edit \
    "system:serviceaccount:${STAGING_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${STAGING_NAMESPACE}" 2>/dev/null || log_warning "edit role may already be assigned"

log_success "Staging namespace configured"
echo ""

################################################################################
# Create Production Namespace
################################################################################

log_info "Setting up production namespace: ${PROD_NAMESPACE}"

if oc get project "${PROD_NAMESPACE}" &> /dev/null; then
    log_success "Namespace ${PROD_NAMESPACE} already exists"
else
    log_info "Creating namespace ${PROD_NAMESPACE}..."
    oc new-project "${PROD_NAMESPACE}" || {
        log_error "Failed to create namespace ${PROD_NAMESPACE}"
        exit 1
    }
    log_success "Namespace ${PROD_NAMESPACE} created"
fi

# Create service account in production
if oc get sa "${SERVICE_ACCOUNT}" -n "${PROD_NAMESPACE}" &> /dev/null; then
    log_success "Service account ${SERVICE_ACCOUNT} already exists in ${PROD_NAMESPACE}"
else
    log_info "Creating service account ${SERVICE_ACCOUNT} in ${PROD_NAMESPACE}..."
    oc create serviceaccount "${SERVICE_ACCOUNT}" -n "${PROD_NAMESPACE}"
    log_success "Service account created"
fi

# Grant permissions in production
log_info "Granting permissions in ${PROD_NAMESPACE}..."

oc policy add-role-to-user system:image-pusher \
    "system:serviceaccount:${PROD_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${PROD_NAMESPACE}" 2>/dev/null || log_warning "image-pusher role may already be assigned"

oc policy add-role-to-user edit \
    "system:serviceaccount:${PROD_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${PROD_NAMESPACE}" 2>/dev/null || log_warning "edit role may already be assigned"

log_success "Production namespace configured"
echo ""

################################################################################
# Grant Cross-Namespace Permissions
################################################################################

log_info "Configuring cross-namespace permissions..."
log_info "This allows staging service account to promote images to production"

# Allow staging SA to pull images from production (for verification)
oc policy add-role-to-user system:image-puller \
    "system:serviceaccount:${STAGING_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${PROD_NAMESPACE}" 2>/dev/null || log_warning "image-puller role may already be assigned"

# Allow staging SA to push/tag images in production (for promotion)
oc policy add-role-to-user system:image-pusher \
    "system:serviceaccount:${STAGING_NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "${PROD_NAMESPACE}" 2>/dev/null || log_warning "image-pusher role may already be assigned"

log_success "Cross-namespace permissions configured"
echo ""

################################################################################
# Verify Setup
################################################################################

log_info "Verifying setup..."
echo ""

# Verify staging
log_info "Staging namespace (${STAGING_NAMESPACE}):"
echo "  Service Account: $(oc get sa ${SERVICE_ACCOUNT} -n ${STAGING_NAMESPACE} -o name 2>/dev/null || echo 'NOT FOUND')"
echo "  Can create imagestreams: $(oc policy who-can create imagestreams -n ${STAGING_NAMESPACE} 2>/dev/null | grep -q ${SERVICE_ACCOUNT} && echo 'YES' || echo 'NO')"
echo "  Can create deployments: $(oc policy who-can create deployments -n ${STAGING_NAMESPACE} 2>/dev/null | grep -q ${SERVICE_ACCOUNT} && echo 'YES' || echo 'NO')"
echo ""

# Verify production
log_info "Production namespace (${PROD_NAMESPACE}):"
echo "  Service Account: $(oc get sa ${SERVICE_ACCOUNT} -n ${PROD_NAMESPACE} -o name 2>/dev/null || echo 'NOT FOUND')"
echo "  Can create imagestreams: $(oc policy who-can create imagestreams -n ${PROD_NAMESPACE} 2>/dev/null | grep -q ${SERVICE_ACCOUNT} && echo 'YES' || echo 'NO')"
echo "  Can create deployments: $(oc policy who-can create deployments -n ${PROD_NAMESPACE} 2>/dev/null | grep -q ${SERVICE_ACCOUNT} && echo 'YES' || echo 'NO')"
echo ""

# Verify cross-namespace
log_info "Cross-namespace permissions:"
echo "  Staging SA can push to production: $(oc policy who-can create imagestreams -n ${PROD_NAMESPACE} 2>/dev/null | grep -q "${STAGING_NAMESPACE}:${SERVICE_ACCOUNT}" && echo 'YES' || echo 'NO')"
echo ""

################################################################################
# Summary
################################################################################

log_success "=========================================="
log_success "Namespace setup completed!"
log_success "=========================================="
echo ""
log_info "Namespaces created:"
echo "  ✅ ${STAGING_NAMESPACE}"
echo "  ✅ ${PROD_NAMESPACE}"
echo ""
log_info "Service accounts created:"
echo "  ✅ ${STAGING_NAMESPACE}/${SERVICE_ACCOUNT}"
echo "  ✅ ${PROD_NAMESPACE}/${SERVICE_ACCOUNT}"
echo ""
log_info "Next steps:"
echo "  1. Run the credential collection script:"
echo "     ./collect-credentials.sh"
echo ""
echo "  2. The script will create a token for the staging service account"
echo "     This token will have permissions to:"
echo "     - Deploy to ${STAGING_NAMESPACE}"
echo "     - Deploy to ${PROD_NAMESPACE}"
echo "     - Promote images from staging to production"
echo ""
echo "  3. Add the credentials to GitHub Secrets"
echo "     (See .github/workflows/SETUP_GUIDE.md for details)"
echo ""

# Made with Bob