# Production Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying HexBuzz to production, including Firebase services, web hosting, and app store submissions.

## Prerequisites

Before deploying to production, ensure all items in the [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md) are completed.

### Quick Pre-Deployment Checks

```bash
# 1. Run all tests
flutter test

# 2. Check code quality
flutter analyze
dart format . --set-exit-if-changed

# 3. Build and lint Cloud Functions
cd functions
npm run lint
npm run build
cd ..

# 4. Verify Firebase configuration
firebase projects:list
```

## Firebase Project Setup

### 1. Create Firebase Project

If you haven't already created a production Firebase project:

```bash
# Login to Firebase
firebase login

# Create new project (or use existing)
firebase use --add

# Select or create project, alias it as "production"
# This creates .firebaserc file
```

### 2. Configure Firebase Services

Enable the following services in Firebase Console:

- **Authentication**: Enable Google Sign-In provider
- **Firestore Database**: Create in production mode
- **Cloud Functions**: Enable billing (required for production)
- **Cloud Messaging (FCM)**: Enable for notifications
- **Performance Monitoring**: Enable for monitoring
- **Crashlytics**: Enable for crash reporting
- **Hosting**: Enable for web app

### 3. Configure Environment Variables

Set up secrets for Cloud Functions:

```bash
# Set Firebase configuration
firebase functions:secrets:set FIREBASE_CONFIG

# Add any other required secrets
firebase functions:secrets:set GOOGLE_CLIENT_ID
firebase functions:secrets:set GOOGLE_CLIENT_SECRET
```

## Phase 1: Deploy Firebase Backend

### Step 1: Deploy Firestore Rules and Indexes

```bash
# Validate Firestore rules
firebase deploy --only firestore:rules --project production

# Deploy indexes (this may take 5-15 minutes)
firebase deploy --only firestore:indexes --project production

# Monitor index creation
firebase firestore:indexes --project production
```

**Wait for all indexes to complete before proceeding.**

### Step 2: Deploy Cloud Functions

```bash
# Build functions
cd functions
npm run build
cd ..

# Deploy all functions
firebase deploy --only functions --project production

# Or deploy individual functions
firebase deploy --only functions:onScoreUpdate --project production
firebase deploy --only functions:generateDailyChallenge --project production
firebase deploy --only functions:sendDailyChallengeNotifications --project production
firebase deploy --only functions:onUserCreated --project production
firebase deploy --only functions:recomputeAllRanks --project production
```

**Deployment time:** 5-10 minutes

### Step 3: Verify Cloud Functions

```bash
# Check function logs
firebase functions:log --project production

# Test scheduled function (generateDailyChallenge)
firebase functions:shell --project production
# In shell:
# generateDailyChallenge()

# Verify all functions are deployed
firebase functions:list --project production
```

## Phase 2: Deploy Web Application

### Step 1: Build Flutter Web App

```bash
# Build for production with CanvasKit renderer (better performance)
flutter build web --release --web-renderer canvaskit

# Or use HTML renderer (smaller bundle size)
flutter build web --release --web-renderer html
```

**Build output:** `build/web/`

### Step 2: Prepare Legal Documents

```bash
# Copy legal documents to build
./scripts/prepare-hosting.sh

# Or manually:
cp public/privacy-policy.html build/web/
cp public/terms-of-service.html build/web/
```

### Step 3: Deploy to Firebase Hosting

```bash
# Deploy hosting
firebase deploy --only hosting --project production

# Get hosting URL
firebase hosting:channel:list --project production
```

**Production URL:** https://hex-buzz.web.app or your custom domain

### Step 4: Verify Web Deployment

1. Visit https://hex-buzz.web.app
2. Test authentication (Google Sign-In)
3. Test gameplay (complete a level)
4. Check leaderboard loads
5. Test daily challenge
6. Verify notifications (if enabled in browser)
7. Check browser console for errors

## Phase 3: Monitor Initial Deployment

### First 30 Minutes

```bash
# Monitor Cloud Function logs
firebase functions:log --project production --follow

# Check error rates
# Visit Firebase Console → Functions → Dashboard
```

**What to watch for:**
- No increase in error rates
- Function execution times within SLOs (< 10s for most)
- Firestore read/write quotas normal
- No authentication failures

### First Hour

1. **Check Firebase Console:**
   - Functions: Execution count, error rate, latency
   - Firestore: Read/write operations, quota usage
   - Authentication: New user sign-ups
   - Hosting: Request count, bandwidth

2. **Check Performance Monitoring:**
   - App load time < 3 seconds
   - No frozen frames
   - Network requests succeeding

3. **Check Crashlytics:**
   - Zero new crashes expected
   - If crashes appear, investigate immediately

### First Day

- Monitor every 2-4 hours
- Check user feedback (if any channels available)
- Review analytics events
- Check notification delivery rates
- Monitor Cloud Functions costs

## Phase 4: App Store Submissions

### Google Play Store (Android)

**Note:** This project currently focuses on web and Windows platforms. Android deployment requires additional configuration.

### Apple App Store (iOS)

**Note:** This project currently focuses on web and Windows platforms. iOS deployment requires additional configuration and Apple Developer Program membership.

### Microsoft Store (Windows)

See dedicated guide: [Microsoft Store Submission Guide](./MS_STORE_SUBMISSION.md)

**Prerequisites:**
1. Microsoft Partner Center account ($19 one-time fee)
2. App name "HexBuzz" reserved
3. Privacy policy deployed to public URL
4. Screenshots captured (4-8 at 1920x1080)
5. MSIX package built and WACK-tested

**Quick submission steps:**

```bash
# 1. Build MSIX package
flutter pub run msix:create

# 2. Run WACK validation
# (On Windows machine)
.\run_wack_tests.ps1

# 3. Upload to Partner Center
# Follow guide in MS_STORE_SUBMISSION.md
```

**Certification time:** 1-3 business days

## Phase 5: Post-Deployment Validation

### Automated Validation Script

```bash
# Run post-deployment validation
./scripts/validate-production.sh
```

This script checks:
- Web app loads successfully
- API endpoints respond correctly
- Authentication works
- Cloud Functions are reachable
- Firestore rules are applied

### Manual Validation Checklist

- [ ] Web app loads at production URL
- [ ] Google Sign-In works correctly
- [ ] Guest mode works correctly
- [ ] Level selection displays correctly
- [ ] Gameplay functions properly
- [ ] Level completion saves progress
- [ ] Leaderboard loads and displays data
- [ ] Daily challenge is available
- [ ] Daily challenge completion works
- [ ] Notifications can be toggled in settings
- [ ] Privacy policy link works
- [ ] Terms of service link works
- [ ] All themes render correctly
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Browser back button works correctly
- [ ] Page refresh preserves state appropriately

### Performance Benchmarks

Expected metrics for production:

- **App Load Time:** < 3 seconds (first load), < 1 second (cached)
- **Time to Interactive:** < 5 seconds
- **Leaderboard Load:** < 2 seconds
- **Daily Challenge Load:** < 2 seconds
- **Level Completion Submit:** < 1 second
- **Cloud Function P95 Latency:** < 10 seconds
- **Firestore Query P95 Latency:** < 2 seconds

### Cost Monitoring

Monitor Firebase costs daily for first week:

```bash
# Check current usage
firebase projects:list
# Visit Firebase Console → Usage and Billing
```

**Expected costs** (1,000 daily active users):
- **Firestore:** $10-20/month
- **Cloud Functions:** $20-40/month
- **Hosting:** $0-5/month (within free tier)
- **Cloud Messaging:** Free tier sufficient
- **Total:** ~$30-65/month

Refer to [Monitoring Guide](./MONITORING.md) for cost optimization strategies.

## Rollback Procedures

### Rolling Back Cloud Functions

```bash
# List function deployment history
gcloud functions list --project=<PROJECT_ID>

# Rollback specific function
firebase functions:delete onScoreUpdate --project production
firebase deploy --only functions:onScoreUpdate --project production

# Or use gcloud directly
gcloud functions deploy onScoreUpdate --source=. --project=<PROJECT_ID>
```

### Rolling Back Hosting

```bash
# List hosting releases
firebase hosting:releases:list --project production

# Rollback to previous release
firebase hosting:rollback --project production
```

### Rolling Back Firestore Rules

```bash
# Checkout previous version from git
git log firestore.rules
git checkout <commit-hash> firestore.rules

# Deploy previous rules
firebase deploy --only firestore:rules --project production

# Revert git checkout
git checkout main firestore.rules
```

### Emergency Rollback Script

```bash
#!/bin/bash
# emergency-rollback.sh

echo "Starting emergency rollback..."

# Rollback hosting
echo "Rolling back hosting..."
firebase hosting:rollback --project production

# Rollback Firestore rules to last known good version
echo "Rolling back Firestore rules..."
git checkout HEAD~1 firestore.rules
firebase deploy --only firestore:rules --project production

# Note: Cloud Functions rollback requires manual intervention
echo "Cloud Functions must be rolled back manually"
echo "See documentation for details"

echo "Rollback complete. Monitor logs closely."
```

## CI/CD Pipeline

For automated deployments, see [CI/CD Documentation](./CICD.md).

### GitHub Actions Workflows

Production deployment is triggered by:

```bash
# Merge develop to main
git checkout main
git pull origin main
git merge develop
git push origin main

# Or create release tag
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will:
1. Run all tests
2. Build Flutter web app
3. Build Cloud Functions
4. Deploy to Firebase production (with approval gate)
5. Create release artifacts

### Manual Deployment Script

For manual deployments (without CI/CD):

```bash
#!/bin/bash
# deploy-production.sh

set -e

echo "🚀 Starting HexBuzz Production Deployment"
echo "=========================================="

# Pre-checks
echo "Running pre-deployment checks..."
flutter test || exit 1
flutter analyze || exit 1
dart format . --set-exit-if-changed || exit 1

echo "Building Cloud Functions..."
cd functions
npm run lint || exit 1
npm run build || exit 1
cd ..

echo "Building Flutter web app..."
flutter build web --release --web-renderer canvaskit || exit 1

echo "Preparing legal documents..."
./scripts/prepare-hosting.sh || exit 1

# Confirm deployment
echo ""
read -p "Deploy to PRODUCTION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 1
fi

echo "Deploying to Firebase production..."
firebase use production
firebase deploy --project production || exit 1

echo ""
echo "✅ Deployment complete!"
echo "Production URL: https://hex-buzz.web.app"
echo ""
echo "Next steps:"
echo "1. Monitor logs: firebase functions:log --project production --follow"
echo "2. Check Firebase Console for errors"
echo "3. Verify production URL loads correctly"
echo "4. Run post-deployment validation"
```

## Monitoring and Alerts

### Set Up Monitoring

1. **Firebase Console:**
   - Navigate to Functions → Metrics
   - Set up alerts for error rates > 5%
   - Set up alerts for P95 latency > 10s

2. **Cloud Monitoring:**
   - Create dashboard for key metrics
   - Configure email/Slack notifications
   - Set up uptime checks for web app

3. **Performance Monitoring:**
   - Verify data is flowing in
   - Set performance budgets
   - Configure alerts for slow page loads

See [Monitoring Guide](./MONITORING.md) for detailed setup.

### Alert Configuration

```bash
# Set up monitoring
cd monitoring
./setup-monitoring.sh --project production
```

This configures:
- Cloud Function error rate alerts
- Firestore quota alerts
- Hosting error rate alerts
- Performance monitoring alerts
- Cost alerts

## Troubleshooting

### Common Deployment Issues

#### Issue: Firebase deploy fails with authentication error

```bash
# Solution: Re-authenticate
firebase logout
firebase login
firebase use production
```

#### Issue: Cloud Functions fail to deploy

```bash
# Check for TypeScript errors
cd functions
npm run build

# Check Node version (should be 20)
node --version

# Clear cache and retry
npm run clean
npm install
npm run build
firebase deploy --only functions --project production
```

#### Issue: Firestore indexes taking too long

- Indexes can take 5-30 minutes for large datasets
- Check status: `firebase firestore:indexes --project production`
- If stuck, delete and recreate in Firebase Console

#### Issue: Web app shows white screen

```bash
# Check browser console for errors
# Common causes:
# 1. Firebase not initialized - check firebase config
# 2. Firestore rules blocking access
# 3. Missing assets

# Verify build
ls -la build/web
```

#### Issue: Authentication not working

1. Verify Google OAuth is configured in Firebase Console
2. Check authorized domains include production URL
3. Verify Firebase config in web app
4. Check browser console for errors

### Getting Help

- **Firebase Support:** Firebase Console → Support
- **GitHub Issues:** https://github.com/yourusername/hex_buzz/issues
- **Documentation:** Check all docs in `docs/` directory

## Production Checklist Summary

### Before Deployment

- [ ] All tests passing (1100+ tests)
- [ ] Code analysis clean
- [ ] Cloud Functions build successfully
- [ ] Firebase project configured
- [ ] Secrets configured
- [ ] Legal documents prepared
- [ ] Monitoring configured
- [ ] Rollback plan ready
- [ ] Team notified

### Deployment Steps

- [ ] Deploy Firestore rules and indexes
- [ ] Wait for indexes to complete
- [ ] Deploy Cloud Functions
- [ ] Verify functions deployed
- [ ] Build Flutter web app
- [ ] Deploy to Firebase Hosting
- [ ] Verify web app loads

### Post-Deployment

- [ ] Monitor logs (30 minutes)
- [ ] Check error rates
- [ ] Verify all features work
- [ ] Monitor performance metrics
- [ ] Monitor costs
- [ ] Document any issues
- [ ] Team notified of success

## Version History

| Version | Date | Deployed By | Changes | Status |
|---------|------|-------------|---------|--------|
| 1.0.0   | YYYY-MM-DD | [Name] | Initial production release | ✅ |

## Resources

- [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md)
- [CI/CD Documentation](./CICD.md)
- [Firebase Deployment Guide](../functions/DEPLOYMENT.md)
- [Microsoft Store Submission](./MS_STORE_SUBMISSION.md)
- [Monitoring Guide](./MONITORING.md)
- [Security Testing Report](./SECURITY_TESTING_REPORT.md)
- [User Guide](./USER_GUIDE.md)

## Next Steps After Production

1. **Monitor for 48 hours** - Watch for any issues
2. **Submit to Microsoft Store** - Follow MS Store guide
3. **Create marketing materials** - Screenshots, videos
4. **Set up analytics** - Track user behavior
5. **Plan first update** - Bug fixes, feature additions
6. **Gather user feedback** - Reviews, surveys
7. **Optimize performance** - Based on real-world data
8. **Scale infrastructure** - If user base grows

## Notes

- Always deploy during low-traffic hours
- Never deploy on Fridays (limits monitoring time)
- Keep rollback scripts ready
- Document all deployment issues
- Communicate with team throughout process
- Monitor costs daily for first week
- Respond to user feedback promptly

---

**Last Updated:** 2026-01-17
**Document Version:** 1.0
**Maintainer:** Development Team
