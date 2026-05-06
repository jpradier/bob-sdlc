#!/usr/bin/env bash
################################################################################
# Pre-Setup Check Script
################################################################################
#
# This script checks if you have the right permissions to set up CI/CD
# and guides you through the process.
#
################################################################################

set -e

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

echo ""
log_info "=========================================="
log_info "CI/CD Setup Pre-Check"
log_info "=========================================="
echo ""

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    log_error "OpenShift CLI (oc) is not installed"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    log_error "Not logged into OpenShift"
    echo ""
    log_info "Please login first:"
    echo "  oc login --server=https://api.itz-bsvdb8.pok-lb.techzone.ibm.com:6443 --token=<your-admin-token>"
    exit 1
fi

CURRENT_USER=$(oc whoami)
log_info "Current user: ${CURRENT_USER}"
echo ""

# Check if user is a service account
if [[ "${CURRENT_USER}" == system:serviceaccount:* ]]; then
    log_error "You are logged in as a service account!"
    log_error "Service accounts cannot create projects or manage other namespaces."
    echo ""
    log_warning "Current user: ${CURRENT_USER}"
    echo ""
    log_info "You need to logout and login as a cluster admin:"
    echo ""
    echo "  # Step 1: Logout from service account"
    echo "  oc logout"
    echo ""
    echo "  # Step 2: Login as cluster admin"
    echo "  oc login --server=https://api.itz-bsvdb8.pok-lb.techzone.ibm.com:6443 --token=<admin-token>"
    echo ""
    echo "  # Step 3: Run this script again"
    echo "  ./check-and-setup.sh"
    echo ""
    log_info "To get your admin token:"
    echo "  1. Login to OpenShift web console"
    echo "  2. Click your username (top right)"
    echo "  3. Click 'Copy login command'"
    echo "  4. Click 'Display Token'"
    echo "  5. Copy the token and use it in the oc login command above"
    echo ""
    exit 1
fi

# Check if user can create projects
log_info "Checking permissions..."
if oc auth can-i create projects &> /dev/null; then
    log_success "✅ You have permission to create projects"
else
    log_error "❌ You don't have permission to create projects"
    echo ""
    log_info "You need cluster-admin or self-provisioner role."
    log_info "Contact your cluster administrator to grant you project creation rights."
    echo ""
    exit 1
fi

# Check if namespaces already exist
log_info "Checking existing namespaces..."
STAGING_EXISTS=false
PROD_EXISTS=false

if oc get project bob-demo-staging &> /dev/null; then
    log_success "✅ bob-demo-staging namespace exists"
    STAGING_EXISTS=true
else
    log_warning "⚠️  bob-demo-staging namespace does not exist"
fi

if oc get project bob-demo-prod &> /dev/null; then
    log_success "✅ bob-demo-prod namespace exists"
    PROD_EXISTS=true
else
    log_warning "⚠️  bob-demo-prod namespace does not exist"
fi

echo ""

# Decide what to do
if [ "$STAGING_EXISTS" = true ] && [ "$PROD_EXISTS" = true ]; then
    log_success "Both namespaces exist!"
    echo ""
    log_info "Next steps:"
    echo "  1. Run: ./collect-credentials.sh"
    echo "  2. Add credentials to GitHub Secrets"
    echo "  3. See QUICK_START.md for details"
    echo ""
else
    log_info "Ready to create namespaces and set up CI/CD!"
    echo ""
    log_info "Run the setup script:"
    echo "  ./setup-cicd-namespaces.sh"
    echo ""
fi

# Made with Bob