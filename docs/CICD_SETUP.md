# CI/CD Pipeline Setup Guide

Quick start guide for setting up the CI/CD pipeline for HexBuzz.

## Prerequisites

- GitHub repository with admin access
- Firebase projects (staging and production)
- Firebase CLI installed locally
- Google Cloud project (same as Firebase)

## Setup Steps

### 1. Firebase CI Token Generation

Generate CI tokens for automated deployment:

```bash
# Login to Firebase CLI
firebase login

# Generate CI token
firebase login:ci
```

Copy the token that is displayed. You'll need it for GitHub secrets.

### 2. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value | Required |
|-------------|-------|----------|
| `FIREBASE_TOKEN_PRODUCTION` | Token from `firebase login:ci` | Yes |
| `FIREBASE_TOKEN_STAGING` | Token from `firebase login:ci` (for staging project) | No |
| `CODECOV_TOKEN` | Token from codecov.io | No |

**To add a secret:**
- Click "New repository secret"
- Name: Enter secret name exactly as shown above
- Secret: Paste the token value
- Click "Add secret"

### 3. Configure Firebase Projects

Create `.firebaserc` file in repository root (if not exists):

```json
{
  "projects": {
    "default": "hex-buzz-prod",
    "production": "hex-buzz-prod",
    "staging": "hex-buzz-staging"
  }
}
```

Replace project IDs with your actual Firebase project IDs.

### 4. Setup GitHub Environments

#### Create Production Environment

1. Go to: **Settings** → **Environments**
2. Click **New environment**
3. Name: `production`
4. Click **Configure environment**
5. Add protection rules:
   - ☑️ **Required reviewers**: Add yourself or team members (1+)
   - ☑️ **Wait timer**: 0 minutes (or set delay if desired)
   - ☑️ **Deployment branches**: Select "Selected branches"
     - Add rule: `main` branch only
6. Click **Save protection rules**

This ensures production deployments require approval.

### 5. Configure Branch Protection

#### Main Branch Protection

1. Go to: **Settings** → **Branches**
2. Click **Add branch protection rule**
3. Branch name pattern: `main`
4. Configure rules:
   - ☑️ **Require a pull request before merging**
     - ☑️ Require approvals: 1
   - ☑️ **Require status checks to pass before merging**
     - ☑️ Require branches to be up to date before merging
     - Search and add status checks:
       - `test`
       - `lint-functions`
       - `code-quality`
       - `firebase-config-validation`
   - ☑️ **Require conversation resolution before merging**
   - ☑️ **Do not allow bypassing the above settings**
5. Click **Create**

#### Develop Branch Protection

1. Add another branch protection rule
2. Branch name pattern: `develop`
3. Configure rules:
   - ☑️ **Require a pull request before merging**
   - ☑️ **Require status checks to pass before merging**
     - Add: `test`, `lint-functions`
4. Click **Create**

### 6. Update MSIX Publisher ID

For Windows builds, update the Publisher ID in `pubspec.yaml`:

1. Go to [Microsoft Partner Center](https://partner.microsoft.com/)
2. Create account if not exists ($19 one-time fee)
3. Navigate to: **Apps and games** → **Overview**
4. Find your Publisher ID (format: `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)
5. Update `pubspec.yaml`:
   ```yaml
   msix_config:
     publisher: CN=YOUR-ACTUAL-PUBLISHER-ID
   ```

### 7. Test CI/CD Pipeline

#### Test with a Simple Change

```bash
# Create feature branch
git checkout -b feature/test-cicd

# Make a small change (e.g., update README)
echo "# CI/CD Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: verify CI/CD pipeline"
git push origin feature/test-cicd
```

#### Create Pull Request

1. Go to GitHub repository
2. Click **Pull requests** → **New pull request**
3. Base: `develop`, Compare: `feature/test-cicd`
4. Click **Create pull request**
5. Wait for checks to complete
6. Verify all checks pass (green checkmarks)

#### Deploy to Staging

```bash
# Merge PR to develop
git checkout develop
git merge feature/test-cicd
git push origin develop
```

Watch the GitHub Actions tab to see staging deployment.

#### Deploy to Production

```bash
# Merge develop to main
git checkout main
git merge develop
git push origin main
```

1. Go to GitHub Actions tab
2. Find the "Test and Deploy" workflow run
3. Click on the run
4. Click **Review deployments**
5. Select `production` environment
6. Click **Approve and deploy**

Watch the deployment complete.

### 8. Verify Deployment

#### Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your production project
3. Check:
   - **Functions**: Verify functions are deployed
   - **Firestore**: Check rules and indexes deployed
   - **Hosting**: Verify web app deployed

#### Test Web App

Visit your hosting URL (e.g., https://hex-buzz.web.app) and verify:
- App loads correctly
- Authentication works
- Leaderboard displays
- Daily challenge functions

### 9. Create First Windows Release

```bash
# Tag release
git tag v1.0.0
git push origin v1.0.0
```

1. Go to GitHub Actions tab
2. Watch "Build Windows MSIX" workflow
3. Once complete, go to **Releases**
4. Find draft release for v1.0.0
5. Review release notes
6. Click **Publish release**
7. Download MSIX artifact from releases

## Verification Checklist

After setup, verify:

- [ ] All GitHub secrets configured
- [ ] Firebase projects linked in `.firebaserc`
- [ ] Production environment created with protections
- [ ] Branch protection rules active
- [ ] Test PR triggers all checks
- [ ] Staging deployment works on `develop` push
- [ ] Production deployment requires approval
- [ ] Windows MSIX builds on version tags
- [ ] All workflows show green status

## Common Issues

### Issue: "Invalid Firebase token"

**Cause**: Token expired or incorrect

**Solution**:
```bash
firebase login:ci
# Update GitHub secret with new token
```

### Issue: "Project not found"

**Cause**: Firebase project ID incorrect in `.firebaserc`

**Solution**:
1. Check project ID in Firebase Console
2. Update `.firebaserc` with correct ID
3. Commit and push

### Issue: "Required status check not found"

**Cause**: Status check names don't match workflow job names

**Solution**:
1. Go to GitHub Actions tab
2. Click on a workflow run
3. Note exact job names
4. Update branch protection rules to match

### Issue: "Publisher ID not set" in Windows build

**Cause**: Placeholder Publisher ID in `pubspec.yaml`

**Solution**:
1. Get real Publisher ID from Partner Center
2. Update `pubspec.yaml`
3. Commit and push
4. Retag release

## Next Steps

After successful setup:

1. **Monitor First Deployments**
   - Watch logs in Firebase Console
   - Check error rates
   - Verify performance metrics

2. **Setup Monitoring**
   - Follow [Monitoring Guide](./MONITORING.md)
   - Configure alerts
   - Setup dashboards

3. **Team Training**
   - Share CI/CD documentation
   - Review deployment procedures
   - Establish on-call rotation

4. **Optimize Pipeline**
   - Review workflow execution times
   - Optimize caching
   - Add more checks if needed

## Resources

- [Full CI/CD Documentation](./CICD.md)
- [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md)
- [Firebase Deployment Guide](../functions/DEPLOYMENT.md)
- [GitHub Actions Quick Reference](../.github/README.md)

## Support

For setup issues:

1. Check workflow logs in GitHub Actions
2. Review error messages carefully
3. Verify all secrets are configured
4. Check Firebase project permissions
5. Consult full CICD documentation
6. Open issue with detailed error info

## Estimated Setup Time

- Initial setup: 30-60 minutes
- Testing and verification: 30 minutes
- Total: 1-1.5 hours

With these steps complete, your CI/CD pipeline will be fully operational!
