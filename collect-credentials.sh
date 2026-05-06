#!/usr/bin/env bash
set -e

echo "🔐 Collecting OpenShift Credentials for GitHub Actions"
echo "======================================================"
echo ""

# Initialize .env file
cat > .env << 'ENVFILE'
# GitHub Actions CI/CD Credentials
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
#
# ⚠️  SECURITY WARNING:
# This file contains sensitive credentials. Never commit to Git!
# The .gitignore file should already exclude this file.
#
# These values should be added to GitHub repository:
# Settings → Secrets and variables → Actions

ENVFILE

echo "📍 Step 1: Getting OpenShift Server URL..."
OPENSHIFT_SERVER=$(oc whoami --show-server)
echo "OPENSHIFT_SERVER=${OPENSHIFT_SERVER}" >> .env
echo "   ✅ OPENSHIFT_SERVER=${OPENSHIFT_SERVER}"
echo ""

echo "🔑 Step 2: Creating Service Account Token (valid for 1 year)..."
OPENSHIFT_TOKEN=$(oc create token github-actions -n bob-demo-staging --duration=8760h)
echo "OPENSHIFT_TOKEN=${OPENSHIFT_TOKEN}" >> .env
echo "   ✅ OPENSHIFT_TOKEN=${OPENSHIFT_TOKEN:0:20}... (truncated for security)"
echo ""

echo "🐳 Step 3: Getting Registry URL..."
OPENSHIFT_REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}' 2>/dev/null || echo "image-registry.openshift-image-registry.svc:5000")
echo "OPENSHIFT_REGISTRY=${OPENSHIFT_REGISTRY}" >> .env
echo "   ✅ OPENSHIFT_REGISTRY=${OPENSHIFT_REGISTRY}"
echo ""

echo "🌐 Step 4: Getting Cluster Domain..."
CLUSTER_DOMAIN=$(oc get route -A -o jsonpath='{.items[0].spec.host}' 2>/dev/null | sed 's/^[^.]*\.//' || echo "apps.cluster.example.com")
echo "CLUSTER_DOMAIN=${CLUSTER_DOMAIN}" >> .env
echo "   ✅ CLUSTER_DOMAIN=${CLUSTER_DOMAIN}"
echo ""

echo "======================================================"
echo "✅ Credentials saved to .env file"
echo ""
echo "📋 Next steps:"
echo "   1. Review the .env file: cat .env"
echo "   2. Test credentials: source .env && oc login --token=\"\$OPENSHIFT_TOKEN\" --server=\"\$OPENSHIFT_SERVER\""
echo "   3. Add these values to GitHub Secrets (see Step 3 in SETUP_GUIDE.md)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Set calendar reminder to rotate token in 11 months"
echo "   - Never commit .env to Git (already in .gitignore)"
echo "   - Keep this file secure on your local machine"
echo ""
