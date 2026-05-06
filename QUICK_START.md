# Quick Start Guide - GitHub Actions CI/CD Setup

This guide will help you quickly set up the CI/CD pipeline for the payment application.

## Current Status

Based on the error you're seeing, the GitHub Secrets are not yet configured. Let's fix that!

## Step-by-Step Setup

### Step 1: Login as Cluster Admin

You're currently logged in as a service account. You need to log in as a cluster admin to create both namespaces.

```bash
# Logout from current service account
oc logout

# Login as cluster admin (use your admin credentials)
oc login --server=https://api.itz-bsvdb8.pok-lb.techzone.ibm.com:6443 --token=<your-admin-token>

# Verify you're logged in as admin
oc whoami
```

### Step 2: Run the Namespace Setup Script

```bash
# Make the script executable
chmod +x setup-cicd-namespaces.sh

# Run the setup script
./setup-cicd-namespaces.sh
```

This script will:
- ✅ Create `bob-demo-staging` namespace
- ✅ Create `bob-demo-prod` namespace
- ✅ Create service accounts in both namespaces
- ✅ Grant necessary permissions
- ✅ Configure cross-namespace image promotion

**Expected Output:**
```
[INFO] Starting OpenShift CI/CD namespace setup...
[INFO] Logged in as: kube:admin
[SUCCESS] Namespace bob-demo-staging created
[SUCCESS] Service account created
[SUCCESS] Staging namespace configured
[SUCCESS] Namespace bob-demo-prod created
[SUCCESS] Service account created
[SUCCESS] Production namespace configured
[SUCCESS] Cross-namespace permissions configured
[SUCCESS] Namespace setup completed!
```

### Step 3: Collect Credentials

```bash
# Make the script executable
chmod +x collect-credentials.sh

# Run the credential collection script
./collect-credentials.sh
```

This will create a `.env` file with all required credentials:
```bash
OPENSHIFT_SERVER=https://api.itz-bsvdb8.pok-lb.techzone.ibm.com:6443
OPENSHIFT_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IjRxN...
OPENSHIFT_REGISTRY=default-route-openshift-image-registry.apps.itz-bsvdb8.pok-lb.techzone.ibm.com
CLUSTER_DOMAIN=apps.itz-bsvdb8.pok-lb.techzone.ibm.com
```

### Step 4: Add Secrets to GitHub

#### Option A: Using GitHub Web Interface

1. Go to: https://github.com/jpradier/bob-sdlc/settings/secrets/actions

2. Click **"New repository secret"** for each:

   **Secret 1: OPENSHIFT_SERVER**
   ```bash
   # Copy the value
   source .env && echo $OPENSHIFT_SERVER
   ```
   - Name: `OPENSHIFT_SERVER`
   - Value: Paste the output from above command
   - Click "Add secret"

   **Secret 2: OPENSHIFT_TOKEN**
   ```bash
   # Copy the value
   source .env && echo $OPENSHIFT_TOKEN
   ```
   - Name: `OPENSHIFT_TOKEN`
   - Value: Paste the output from above command
   - Click "Add secret"

   **Secret 3: OPENSHIFT_REGISTRY**
   ```bash
   # Copy the value
   source .env && echo $OPENSHIFT_REGISTRY
   ```
   - Name: `OPENSHIFT_REGISTRY`
   - Value: Paste the output from above command
   - Click "Add secret"

3. Click **"Variables"** tab, then **"New repository variable"**:

   **Variable: CLUSTER_DOMAIN**
   ```bash
   # Copy the value
   source .env && echo $CLUSTER_DOMAIN
   ```
   - Name: `CLUSTER_DOMAIN`
   - Value: Paste the output from above command
   - Click "Add variable"

#### Option B: Using GitHub CLI (if installed)

```bash
# Load credentials
source .env

# Add secrets
gh secret set OPENSHIFT_SERVER --body "$OPENSHIFT_SERVER"
gh secret set OPENSHIFT_TOKEN --body "$OPENSHIFT_TOKEN"
gh secret set OPENSHIFT_REGISTRY --body "$OPENSHIFT_REGISTRY"

# Add variable
gh variable set CLUSTER_DOMAIN --body "$CLUSTER_DOMAIN"

# Verify
gh secret list
gh variable list
```

### Step 5: Configure GitHub Environments

1. Go to: https://github.com/jpradier/bob-sdlc/settings/environments

2. Create **staging** environment:
   - Click "New environment"
   - Name: `staging`
   - Click "Configure environment"
   - Leave protection rules empty (auto-deploy)
   - Click "Save protection rules"

3. Create **production** environment:
   - Click "New environment"
   - Name: `production`
   - Click "Configure environment"
   - ✅ Enable "Required reviewers"
   - Add yourself as a reviewer
   - Click "Save protection rules"

### Step 6: Test the Pipeline

```bash
# Trigger the workflow
git add .
git commit -m "test: Trigger CI/CD pipeline"
git push origin main
```

Then:
1. Go to: https://github.com/jpradier/bob-sdlc/actions
2. Watch the workflow run
3. Approve production deployment when prompted

## Verification Checklist

Before pushing, verify:

- [ ] Both namespaces exist: `oc get projects | grep bob-demo`
- [ ] Service accounts exist: `oc get sa github-actions -n bob-demo-staging`
- [ ] `.env` file created: `cat .env`
- [ ] GitHub Secrets configured: Check repository settings
- [ ] GitHub Variables configured: Check repository settings
- [ ] GitHub Environments configured: Check repository settings

## Troubleshooting

### Issue: "You don't have permissions to create projects"

**Solution:** You need to be logged in as a cluster admin or user with project creation rights.

```bash
# Ask your cluster admin for credentials, then:
oc logout
oc login --server=https://api.itz-bsvdb8.pok-lb.techzone.ibm.com:6443 --token=<admin-token>
```

### Issue: "Service account token not found"

**Solution:** Make sure you ran `setup-cicd-namespaces.sh` first, then run `collect-credentials.sh`.

### Issue: "GitHub Secrets are empty"

**Solution:** You haven't added the secrets to GitHub yet. Follow Step 4 above.

### Issue: "Cannot perform an interactive login from a non TTY device"

**Solution:** This means GitHub Secrets are not configured. The workflow is trying to use empty values. Follow Step 4 to add the secrets.

## Quick Reference Commands

```bash
# View your .env file
cat .env

# Load credentials
source .env

# Test OpenShift login
oc login --token="$OPENSHIFT_TOKEN" --server="$OPENSHIFT_SERVER"

# Check namespaces
oc get projects | grep bob-demo

# Check service accounts
oc get sa github-actions -n bob-demo-staging
oc get sa github-actions -n bob-demo-prod

# View GitHub Secrets (requires gh CLI)
gh secret list

# View GitHub Variables (requires gh CLI)
gh variable list
```

## Next Steps

After the pipeline runs successfully:

1. ✅ Monitor the workflow in GitHub Actions
2. ✅ Check staging deployment: `oc get pods -n bob-demo-staging`
3. ✅ Approve production deployment when ready
4. ✅ Check production deployment: `oc get pods -n bob-demo-prod`

## Support

For detailed documentation, see:
- `.github/workflows/SETUP_GUIDE.md` - Complete setup guide
- `.github/workflows/README.md` - Workflow documentation

---

**Made with Bob** 🤖