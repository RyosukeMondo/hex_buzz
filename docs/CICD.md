# CI/CD Pipeline Documentation

## Overview

This document describes the continuous integration and deployment (CI/CD) pipeline for HexBuzz. The pipeline automates testing, quality checks, and deployment to multiple platforms including Firebase (web, Cloud Functions) and Windows (Microsoft Store).

## Workflows

### 1. Test and Deploy (`test-and-deploy.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**

#### Test Job
- Runs on Ubuntu
- Checks out code
- Sets up Java 17 and Flutter 3.35.6
- Installs dependencies
- Verifies code formatting (`dart format`)
- Analyzes code (`flutter analyze`)
- Runs unit and widget tests with coverage
- Uploads coverage to Codecov (if token configured)

#### Lint Functions Job
- Runs on Ubuntu
- Sets up Node.js 20
- Lints Cloud Functions (`npm run lint`)
- Builds Cloud Functions (`npm run build`)

#### Deploy to Firebase Staging
- **Trigger**: Push to `develop` branch
- **Prerequisites**: Test and lint jobs must pass
- Builds Cloud Functions
- Deploys to Firebase staging project:
  - Cloud Functions
  - Firestore rules and indexes
  - Web hosting

#### Deploy to Firebase Production
- **Trigger**: Push to `main` branch
- **Prerequisites**: Test and lint jobs must pass
- **Environment**: `production` (requires approval if configured)
- Builds Flutter web app with CanvasKit renderer
- Copies legal documents to hosting
- Builds Cloud Functions
- Deploys to Firebase production project:
  - Cloud Functions
  - Firestore rules and indexes
  - Web hosting (https://hex-buzz.web.app)

#### Security Scan
- Runs Trivy vulnerability scanner
- Checks for secrets using TruffleHog
- Uploads results to GitHub Security

### 2. Build Windows MSIX (`build-windows.yml`)

**Triggers:**
- Git tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual workflow dispatch with version input

**Jobs:**

#### Build MSIX
- Runs on Windows
- Sets up Flutter 3.35.6
- Extracts version from tag or input
- Updates version in `pubspec.yaml`
- Verifies Publisher ID is configured
- Builds Windows release (`flutter build windows --release`)
- Creates MSIX package (`flutter pub run msix:create`)
- Runs WACK validation (if installed)
- Creates release artifacts
- Uploads MSIX package and WACK report as artifacts
- Creates draft GitHub Release with:
  - MSIX package
  - Installation instructions
  - Store submission guide

#### Notify Release
- Sends notification about successful build
- Triggered only for tagged releases

### 3. Integration Tests (`integration-tests.yml`)

**Triggers:**
- Pull requests to `main` or `develop` branches
- Daily schedule at 2 AM UTC
- Manual workflow dispatch

**Jobs:**

#### Integration Tests
- Runs on Ubuntu
- Sets up Flutter, Java, and Node.js
- Installs Firebase CLI
- Builds Cloud Functions
- Starts Firebase Emulators (Auth, Firestore, Functions)
- Runs integration tests against emulators
- Stops emulators on completion

#### Firebase Security Tests
- Starts Firestore Emulator
- Runs Firestore security rules tests
- Validates unauthorized access is blocked

#### Load Tests
- **Trigger**: Scheduled runs or manual dispatch only
- Starts Firebase Emulators
- Runs load tests (100+ concurrent users):
  - Score submission test
  - Leaderboard query test
  - Daily challenge test
  - Concurrent user simulation
- Uploads test results as artifacts
- Analyzes and reports performance metrics

### 4. Pre-Deploy Checks (`pre-deploy-checks.yml`)

**Triggers:**
- Pull requests to `main` or `develop` branches
- Manual workflow dispatch

**Jobs:**

#### Code Quality
- Checks file sizes (max 500 lines per file)
- Checks function complexity
- Runs dart_code_metrics for detailed analysis

#### Dependency Audit
- Checks for outdated dependencies
- Validates dependency tree

#### Firebase Configuration Validation
- Validates `firebase.json` exists
- Validates `firestore.rules` exists
- Validates `firestore.indexes.json` exists
- Builds Cloud Functions to verify configuration

#### Documentation Check
- Checks for required documentation:
  - Privacy policy (`public/privacy-policy.html`)
  - Terms of service (`public/terms-of-service.html`)
  - User guide (`docs/USER_GUIDE.md`)
  - Deployment guide (`functions/DEPLOYMENT.md`)
- Scans for TODO/FIXME comments

#### MSIX Validation
- Validates MSIX configuration in `pubspec.yaml`
- Checks Publisher ID is set
- Verifies required MSIX fields

#### Pre-Deploy Summary
- Aggregates results from all checks
- Fails if critical checks fail
- Provides summary of all check results

## Required Secrets

Configure these secrets in GitHub repository settings:

### Firebase Secrets

1. **FIREBASE_TOKEN_STAGING** (Optional)
   - Firebase CI token for staging project
   - Generate with: `firebase login:ci`
   - Used for staging deployments

2. **FIREBASE_TOKEN_PRODUCTION** (Required for production)
   - Firebase CI token for production project
   - Generate with: `firebase login:ci`
   - Used for production deployments

### Optional Secrets

3. **CODECOV_TOKEN** (Optional)
   - Token for uploading coverage to Codecov
   - Get from https://codecov.io

4. **SLACK_WEBHOOK** (Optional, for future enhancement)
   - Slack webhook URL for deployment notifications

## Firebase Project Setup

### Prerequisites

1. Two Firebase projects (recommended):
   - **Staging**: For development testing
   - **Production**: For live app

2. Firebase CLI installed:
   ```bash
   npm install -g firebase-tools
   ```

3. Firebase CLI authentication:
   ```bash
   firebase login:ci
   ```
   Copy the token to GitHub secrets.

### Configure Projects

1. Create `.firebaserc` in repository root:
   ```json
   {
     "projects": {
       "default": "hex-buzz-prod",
       "production": "hex-buzz-prod",
       "staging": "hex-buzz-staging"
     }
   }
   ```

2. Initialize Firebase services:
   ```bash
   firebase use production
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## GitHub Environments

Configure environments for deployment approvals:

1. Go to Repository Settings → Environments
2. Create `production` environment
3. Add protection rules:
   - Required reviewers (1+)
   - Wait timer (optional)
   - Deployment branches: `main` only

## Workflow Execution

### Normal Development Flow

1. **Create feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and push**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

3. **Create pull request**
   - Triggers: Pre-deploy checks, tests, integration tests
   - All checks must pass before merge

4. **Merge to develop**
   ```bash
   git checkout develop
   git merge feature/my-feature
   git push origin develop
   ```
   - Triggers: Staging deployment

5. **Merge develop to main**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```
   - Triggers: Production deployment

### Release Windows Build

1. **Tag release**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   - Triggers: Windows MSIX build workflow

2. **Download artifacts**
   - Go to Actions → Build Windows MSIX → Latest run
   - Download MSIX package
   - Download WACK report (if available)

3. **Test MSIX locally**
   ```powershell
   # Install locally
   Add-AppxPackage -Path HexBuzz-1.0.0.msix

   # Run WACK if not run in CI
   & "${env:ProgramFiles(x86)}\Windows Kits\10\App Certification Kit\appcert.exe" test -appxpackagepath HexBuzz-1.0.0.msix
   ```

4. **Submit to Microsoft Store**
   - Follow guide in `docs/MS_STORE_SUBMISSION.md`
   - Upload MSIX to Partner Center
   - Submit for certification

### Manual Deployments

#### Deploy Firebase manually
```bash
# Deploy to staging
firebase use staging
firebase deploy --only functions,firestore,hosting

# Deploy to production
firebase use production
firebase deploy --only functions,firestore,hosting
```

#### Build Windows MSIX manually
```bash
# Windows machine
flutter build windows --release
flutter pub run msix:create
```

## Monitoring Deployments

### Firebase Console
- **Functions**: Monitor function executions, errors, logs
- **Firestore**: Monitor read/write operations, storage
- **Hosting**: Monitor bandwidth usage, requests

### GitHub Actions
- View workflow runs: Repository → Actions
- Download artifacts: Click on workflow run → Artifacts
- View logs: Click on workflow run → Job → Step

### Alerts
- Configure Firebase alerts in Firebase Console
- Configure GitHub alerts in repository settings
- See `docs/MONITORING.md` for detailed monitoring setup

## Troubleshooting

### Deployment Failures

#### Firebase Token Expired
**Symptoms**: `Error: Invalid or expired token`
**Solution**:
```bash
firebase login:ci
# Update FIREBASE_TOKEN_PRODUCTION secret in GitHub
```

#### Functions Deployment Fails
**Symptoms**: `Error deploying functions`
**Solution**:
1. Check function logs in Firebase Console
2. Verify all dependencies are in `functions/package.json`
3. Test locally:
   ```bash
   cd functions
   npm run build
   firebase emulators:start
   ```

#### MSIX Build Fails
**Symptoms**: `Error creating MSIX package`
**Solution**:
1. Verify Publisher ID is set in `pubspec.yaml`
2. Check Windows build errors:
   ```bash
   flutter build windows --release --verbose
   ```
3. Verify msix package version:
   ```bash
   flutter pub run msix:create --verbose
   ```

### Test Failures

#### Integration Tests Timeout
**Symptoms**: Tests fail with timeout errors
**Solution**:
1. Increase timeout in test file
2. Check Firebase Emulator is running:
   ```bash
   curl http://localhost:8080
   ```
3. Restart emulators:
   ```bash
   firebase emulators:start --only auth,firestore,functions
   ```

#### Security Tests Fail
**Symptoms**: Unauthorized access not blocked
**Solution**:
1. Review Firestore rules in `firestore.rules`
2. Test rules locally:
   ```bash
   firebase emulators:start --only firestore
   bash test/security/firestore_security_emulator_test.sh
   ```

### Coverage Issues

#### Coverage Below Threshold
**Symptoms**: Coverage check fails
**Solution**:
1. Run coverage locally:
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```
2. Add tests for uncovered code
3. Verify test files match pattern `*_test.dart`

## Performance Optimization

### CI/CD Pipeline Speed

1. **Use caching**
   - Flutter SDK cached by `subosito/flutter-action@v2`
   - Node modules cached by `setup-node@v4`
   - Pub dependencies cached automatically

2. **Parallel jobs**
   - Tests and linting run in parallel
   - Separate security scanning job

3. **Conditional execution**
   - Load tests only run on schedule or manual trigger
   - Production deployment only on `main` branch

### Cost Optimization

1. **Free tier usage**
   - GitHub Actions: 2,000 minutes/month for free (public repos unlimited)
   - Firebase: Free tier sufficient for development

2. **Reduce workflow runs**
   - Use `paths` filter for specific file changes
   - Skip CI with `[skip ci]` in commit message (use sparingly)

## Best Practices

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`
- Include ticket number if applicable
- Example: `feat: add daily challenge leaderboard (#123)`

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Feature branches
- `hotfix/*`: Emergency fixes for production

### Testing
- Write tests for all new features
- Maintain >80% code coverage (>90% for critical paths)
- Run tests locally before pushing:
  ```bash
  flutter test
  ```

### Deployment
- Always deploy to staging first
- Test thoroughly in staging before production
- Use feature flags for gradual rollouts (future enhancement)
- Monitor logs after deployment

## Future Enhancements

### Planned Improvements
1. **Android/iOS CI/CD**
   - Build APK/IPA in CI
   - Deploy to Google Play/App Store
   - Automated screenshot generation

2. **Advanced Monitoring**
   - Automated rollback on error threshold
   - Slack/Discord notifications
   - Performance regression detection

3. **Enhanced Security**
   - SAST (Static Application Security Testing)
   - Dependency vulnerability scanning
   - License compliance checks

4. **Infrastructure as Code**
   - Terraform for Firebase configuration
   - Automated environment provisioning

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Firebase CI/CD Documentation](https://firebase.google.com/docs/cli)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Microsoft Store Submission Guide](./MS_STORE_SUBMISSION.md)
- [Monitoring Guide](./MONITORING.md)
- [Security Testing Report](./SECURITY_TESTING_REPORT.md)

## Support

For issues with the CI/CD pipeline:
1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Check Firebase Console for deployment status
4. Open an issue in the repository with:
   - Workflow run URL
   - Error message
   - Steps to reproduce
