# Deployment Checklist

This checklist ensures all steps are completed before deploying HexBuzz to production or releasing new versions.

## Pre-Deployment Checklist

### Code Quality
- [ ] All unit tests passing (`flutter test`)
- [ ] All widget tests passing
- [ ] Integration tests passing
- [ ] Code coverage ≥ 80% (≥ 90% for auth/critical paths)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] No files exceeding 500 lines
- [ ] No functions exceeding 50 lines

### Security
- [ ] Security tests passing
- [ ] Firestore rules validated
- [ ] No secrets in code
- [ ] No exposed API keys
- [ ] Authentication properly secured
- [ ] Rate limiting implemented

### Firebase Configuration
- [ ] `firebase.json` configured correctly
- [ ] `firestore.rules` reviewed and tested
- [ ] `firestore.indexes.json` contains all required indexes
- [ ] Cloud Functions lint and build successfully
- [ ] Cloud Functions tested locally with emulator

### Documentation
- [ ] Privacy policy updated (`public/privacy-policy.html`)
- [ ] Terms of service updated (`public/terms-of-service.html`)
- [ ] User guide current (`docs/USER_GUIDE.md`)
- [ ] Deployment guide current (`functions/DEPLOYMENT.md`)
- [ ] CHANGELOG.md updated with new version
- [ ] README.md reflects current features

### Testing
- [ ] Tested on Android (if applicable)
- [ ] Tested on iOS (if applicable)
- [ ] Tested on Web (all major browsers)
- [ ] Tested on Windows (if releasing MSIX)
- [ ] Tested with Firebase Emulator
- [ ] Load testing completed (for major releases)
- [ ] Performance benchmarks acceptable

## Staging Deployment Checklist

### Pre-Staging
- [ ] All pre-deployment checks complete
- [ ] Develop branch up to date
- [ ] All PRs reviewed and merged
- [ ] CI/CD pipeline passing

### Deploy to Staging
- [ ] Push to `develop` branch
- [ ] Verify GitHub Actions workflow succeeds
- [ ] Check Firebase Console for successful deployment
- [ ] Verify Cloud Functions deployed correctly

### Staging Validation
- [ ] Web app loads at staging URL
- [ ] Authentication works (Google Sign-In)
- [ ] Leaderboard loads correctly
- [ ] Daily challenge functions
- [ ] Score submission works
- [ ] Notifications send correctly
- [ ] All API endpoints respond
- [ ] CLI commands work
- [ ] Monitor logs for errors (15 minutes)

### Staging Issues
If issues found:
- [ ] Document issue
- [ ] Create hotfix branch
- [ ] Fix and test locally
- [ ] Deploy to staging again
- [ ] Revalidate

## Production Deployment Checklist

### Pre-Production
- [ ] All staging validation passed
- [ ] Staging tested for 24+ hours with no critical issues
- [ ] All pre-deployment checks complete
- [ ] Rollback plan prepared
- [ ] Team notified of deployment window

### Version Management
- [ ] Version bumped in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Git tag prepared (e.g., `v1.0.0`)
- [ ] Release notes prepared

### Deploy to Production
- [ ] Merge `develop` to `main`
- [ ] Push to `main` branch
- [ ] Approve deployment in GitHub Actions (if required)
- [ ] Verify GitHub Actions workflow succeeds
- [ ] Check Firebase Console for successful deployment

### Production Validation
- [ ] Web app loads at https://hex-buzz.web.app
- [ ] Authentication works (Google Sign-In)
- [ ] Leaderboard loads correctly
- [ ] Daily challenge functions
- [ ] Score submission works
- [ ] Notifications send correctly
- [ ] All API endpoints respond
- [ ] CLI commands work (if changed)
- [ ] Monitor logs for errors (30 minutes)
- [ ] Check error rates in Firebase Console
- [ ] Verify performance metrics acceptable

### Post-Deployment
- [ ] Monitor Firebase logs for 1 hour
- [ ] Check Firebase Performance Monitoring
- [ ] Review Crashlytics (if any crashes)
- [ ] Verify notification delivery rates
- [ ] Check Firestore quota usage
- [ ] Verify Cloud Functions execution counts
- [ ] Test from multiple devices/locations
- [ ] Verify SSL certificate valid

### Communication
- [ ] Team notified of successful deployment
- [ ] Release notes published (if applicable)
- [ ] Users notified (if major release)
- [ ] Documentation updated

## Windows MSIX Release Checklist

### Pre-Build
- [ ] All pre-deployment checks complete
- [ ] Version bumped in `pubspec.yaml`
- [ ] MSIX version updated (`msix_version`)
- [ ] Publisher ID verified (not placeholder)
- [ ] App icons updated (if changed)
- [ ] CHANGELOG.md updated

### Build MSIX
- [ ] Tag release (`git tag v1.0.0`)
- [ ] Push tag to GitHub (`git push origin v1.0.0`)
- [ ] GitHub Actions builds MSIX successfully
- [ ] Download MSIX artifact from GitHub Actions
- [ ] Download WACK report (if available)

### Local Testing
- [ ] Install MSIX locally on Windows 10
- [ ] Install MSIX locally on Windows 11
- [ ] Verify app launches correctly
- [ ] Test all features:
  - [ ] Authentication
  - [ ] Gameplay
  - [ ] Leaderboard
  - [ ] Daily challenge
  - [ ] Notifications
  - [ ] Settings
- [ ] Test keyboard shortcuts (Ctrl+Z, Escape)
- [ ] Test mouse hover states
- [ ] Test window resizing
- [ ] Uninstall and reinstall to verify clean install

### WACK Validation
- [ ] Run WACK if not run in CI
- [ ] Review WACK report
- [ ] Fix any errors or warnings
- [ ] Re-run WACK until clean
- [ ] Save WACK report for submission

### Store Preparation
- [ ] Privacy policy deployed and accessible
- [ ] Terms of service deployed and accessible
- [ ] Screenshots captured (4-8 at 1920x1080)
- [ ] App description written
- [ ] Keywords optimized
- [ ] Store listing complete
- [ ] Age rating determined

### Microsoft Store Submission
- [ ] Login to Microsoft Partner Center
- [ ] Create new submission (or update existing)
- [ ] Upload MSIX package
- [ ] Upload screenshots
- [ ] Fill out store listing
- [ ] Submit for certification
- [ ] Monitor certification status (1-3 days)

### Post-Submission
- [ ] Respond to certification feedback (if any)
- [ ] Verify app published in store
- [ ] Test install from Microsoft Store
- [ ] Verify all features work
- [ ] Monitor reviews and ratings
- [ ] Monitor crash reports

## Rollback Procedures

### If Production Deployment Fails
1. Check error logs in Firebase Console
2. If critical issue:
   ```bash
   # Rollback to previous Cloud Functions version
   firebase functions:log
   firebase rollback functions:functionName
   ```
3. If web app issue:
   ```bash
   # Rollback hosting
   firebase hosting:rollback
   ```
4. If Firestore rules issue:
   ```bash
   # Revert firestore.rules to previous version
   git checkout HEAD~1 firestore.rules
   firebase deploy --only firestore:rules
   ```

### If Windows Release Has Critical Bug
1. Immediately remove from Microsoft Store (if published)
2. Create hotfix branch
3. Fix bug and test thoroughly
4. Create new version tag
5. Build and test new MSIX
6. Submit updated version to store
7. Monitor certification closely

## Monitoring Schedule

### First Hour After Deployment
- Monitor every 5 minutes
- Check error logs
- Review performance metrics
- Watch for spike in errors

### First Day After Deployment
- Check every hour
- Monitor user feedback
- Watch crash rates
- Review performance

### First Week After Deployment
- Daily monitoring
- Review weekly analytics
- Check for trends
- Address any issues

## Emergency Contacts

### Critical Issues
- **On-call developer**: [Name/Phone]
- **Firebase support**: Firebase Console → Support
- **GitHub Actions**: Check Actions tab for status

### Communication Channels
- **Team Slack**: #deployments channel
- **Email**: team@hexbuzz.app
- **Status page**: (if configured)

## Version History

Keep track of deployments:

| Version | Date | Environment | Deployed By | Notes |
|---------|------|-------------|-------------|-------|
| 1.0.0   | YYYY-MM-DD | Production | [Name] | Initial release |
| 1.0.1   | YYYY-MM-DD | Production | [Name] | Bugfix release |

## Notes

- Always test in staging before production
- Never deploy on Fridays (less monitoring time)
- Schedule major releases during low-traffic hours
- Keep rollback plans ready
- Document all deployment issues for learning

## Resources

- [CI/CD Documentation](./CICD.md)
- [Firebase Deployment Guide](../functions/DEPLOYMENT.md)
- [Microsoft Store Submission Guide](./MS_STORE_SUBMISSION.md)
- [Monitoring Guide](./MONITORING.md)
- [Security Testing Report](./SECURITY_TESTING_REPORT.md)
