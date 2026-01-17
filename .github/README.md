# GitHub Actions Workflows

This directory contains automated CI/CD workflows for HexBuzz.

## Workflows Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Test and Deploy** | Push to main/develop, PRs | Run tests, deploy to Firebase |
| **Build Windows** | Version tags (v*.*.*) | Build MSIX for Microsoft Store |
| **Integration Tests** | PRs, Daily schedule | Run E2E tests with Firebase Emulator |
| **Pre-Deploy Checks** | PRs | Validate code quality and configuration |

## Quick Start

### View Workflow Status
```bash
# Visit GitHub Actions tab
# Or check badge in README.md
```

### Trigger Manual Run
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"
4. Select branch and parameters

### Common Tasks

#### Deploy to Production
```bash
git checkout main
git merge develop
git push origin main
# Automatically triggers production deployment
```

#### Create Windows Release
```bash
git tag v1.0.0
git push origin v1.0.0
# Automatically builds MSIX and creates GitHub Release
```

#### Run Integration Tests
```bash
# Automatically runs on PRs
# Or trigger manually from Actions tab
```

## Workflow Details

### 1. test-and-deploy.yml

**Jobs:**
- `test`: Unit and widget tests with coverage
- `lint-functions`: Lint and build Cloud Functions
- `deploy-firebase-staging`: Deploy to staging (develop branch only)
- `deploy-firebase-production`: Deploy to production (main branch only)
- `security-scan`: Vulnerability and secrets scanning

**Secrets Required:**
- `FIREBASE_TOKEN_STAGING` (optional)
- `FIREBASE_TOKEN_PRODUCTION` (required for production)
- `CODECOV_TOKEN` (optional)

### 2. build-windows.yml

**Jobs:**
- `build-msix`: Build Windows MSIX package
- `notify-release`: Send release notification

**Triggers:**
- Git tags: `v1.0.0`, `v1.2.3`, etc.
- Manual dispatch with version input

**Outputs:**
- MSIX package (uploaded as artifact)
- WACK validation report (if available)
- Draft GitHub Release

### 3. integration-tests.yml

**Jobs:**
- `integration-tests`: E2E tests with Firebase Emulator
- `firebase-security-tests`: Firestore security rules validation
- `load-tests`: Performance testing (scheduled only)

**Triggers:**
- Pull requests
- Daily at 2 AM UTC (for load tests)
- Manual dispatch

**Features:**
- Tests against Firebase Emulator (no cost)
- Generates load test reports
- Validates security rules

### 4. pre-deploy-checks.yml

**Jobs:**
- `code-quality`: File size, complexity checks
- `dependency-audit`: Outdated packages
- `firebase-config-validation`: Config file validation
- `documentation-check`: Required docs present
- `msix-validation`: MSIX configuration check
- `pre-deploy-summary`: Aggregate results

**Triggers:**
- Pull requests
- Manual dispatch

**Purpose:**
- Enforce code quality standards
- Catch configuration issues early
- Ensure documentation up to date

## Configuration

### Required Secrets

Add these in: Repository Settings → Secrets and variables → Actions

1. **FIREBASE_TOKEN_PRODUCTION**
   ```bash
   firebase login:ci
   # Copy token to GitHub secret
   ```

2. **FIREBASE_TOKEN_STAGING** (optional)
   ```bash
   firebase use staging
   firebase login:ci
   # Copy token to GitHub secret
   ```

3. **CODECOV_TOKEN** (optional)
   - Get from https://codecov.io
   - Used for coverage reporting

### Environment Setup

Configure production environment for deployment approval:

1. Go to: Repository Settings → Environments
2. Create `production` environment
3. Add protection rules:
   - Required reviewers: 1+
   - Deployment branches: `main` only

### Branch Protection

Recommended branch protection rules:

**Main Branch:**
- Require pull request before merging
- Require status checks to pass:
  - `test`
  - `lint-functions`
  - `code-quality`
  - `firebase-config-validation`
- Require branches to be up to date
- Require conversation resolution

**Develop Branch:**
- Require pull request before merging
- Require status checks to pass:
  - `test`
  - `lint-functions`

## Monitoring Workflows

### View Workflow Runs
1. Go to Actions tab
2. Select workflow
3. View run history and logs

### Download Artifacts
1. Click on workflow run
2. Scroll to "Artifacts" section
3. Download (e.g., MSIX package, test reports)

### Check Status Badge
Add to README.md:
```markdown
[![CI/CD](https://github.com/yourusername/hex_buzz/workflows/Test%20and%20Deploy/badge.svg)](https://github.com/yourusername/hex_buzz/actions)
```

## Troubleshooting

### Workflow Fails

**Test Failures:**
```bash
# Run tests locally
flutter test
flutter analyze
```

**Deployment Failures:**
```bash
# Check Firebase token
firebase login:ci

# Test deployment locally
firebase use production
firebase deploy --only functions
```

**MSIX Build Failures:**
```bash
# On Windows machine
flutter build windows --release
flutter pub run msix:create
```

### Common Issues

#### Token Expired
**Error**: `Invalid or expired token`
**Fix**: Regenerate Firebase CI token
```bash
firebase login:ci
# Update GitHub secret
```

#### Missing Dependencies
**Error**: `Package not found`
**Fix**: Update dependencies
```bash
flutter pub get
cd functions && npm install
```

#### Publisher ID Not Set
**Error**: `Publisher ID is YourPublisherID`
**Fix**: Update `pubspec.yaml` with real Publisher ID from Microsoft Partner Center

## Cost Optimization

### GitHub Actions Minutes
- **Free tier**: 2,000 minutes/month (private repos)
- **Public repos**: Unlimited

**Tips:**
- Use caching (already configured)
- Run load tests only on schedule
- Skip CI with `[skip ci]` in commit message (use sparingly)

### Firebase Emulator
- **Cost**: Free
- **Usage**: All integration and load tests use emulator
- **Benefits**: No Firebase quota consumption

## Best Practices

### Commit Messages
```bash
# Good
git commit -m "feat: add daily challenge notifications"
git commit -m "fix: resolve leaderboard ranking bug"
git commit -m "docs: update CI/CD documentation"

# Skip CI when needed (use sparingly)
git commit -m "chore: update README [skip ci]"
```

### Pull Requests
1. Create feature branch from `develop`
2. Make changes and test locally
3. Push and create PR to `develop`
4. Wait for all checks to pass
5. Request review
6. Merge after approval

### Releases
1. Merge `develop` to `main` when ready
2. Tag release:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Download MSIX from GitHub Actions
4. Test locally before store submission

## Resources

- [Full CI/CD Documentation](../docs/CICD.md)
- [Firebase Deployment Guide](../functions/DEPLOYMENT.md)
- [Windows Store Submission Guide](../docs/MS_STORE_SUBMISSION.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For CI/CD issues:
1. Check workflow logs in Actions tab
2. Review error messages
3. Check secrets are configured
4. Verify Firebase project is set up
5. Open issue with workflow run link

## Updating Workflows

When modifying workflows:
1. Test in feature branch first
2. Review logs for any issues
3. Document changes in this README
4. Update CICD.md if needed
5. Get review before merging to main
