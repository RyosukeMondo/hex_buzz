# HexBuzz Monitoring and Alerting Guide

This guide covers the complete monitoring and alerting setup for HexBuzz's social and competitive features.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Monitoring Components](#monitoring-components)
4. [Alert Configuration](#alert-configuration)
5. [Dashboards](#dashboards)
6. [Testing Alerts](#testing-alerts)
7. [Incident Response](#incident-response)
8. [Cost Optimization](#cost-optimization)
9. [Troubleshooting](#troubleshooting)

## Overview

HexBuzz uses the following Firebase/GCP monitoring services:

- **Firebase Performance Monitoring**: App performance, screen rendering, network requests
- **Firebase Crashlytics**: Crash reporting and stability monitoring
- **Cloud Monitoring**: Cloud Functions, Firestore, FCM metrics
- **Cloud Logging**: Centralized log aggregation and analysis
- **Alert Policies**: Automated notifications for issues
- **Custom Dashboards**: Real-time operational visibility

### Key Metrics Monitored

| Service | Metrics | SLO Target |
|---------|---------|------------|
| Cloud Functions | Error rate, latency, execution count | 99.5% success, <10s p95 |
| Firestore | Read/write quota, query latency | <2s p95, <80% quota |
| FCM | Delivery rate, error rate | 95% delivery rate |
| App | Crash-free rate, screen render time | 99% crash-free, <1s p95 |

## Quick Start

### Prerequisites

- Firebase project configured
- GCP project with billing enabled
- `gcloud` CLI installed
- `firebase` CLI installed
- Owner or Editor role in GCP project

### 1. Enable Monitoring Services

```bash
# Navigate to project directory
cd /path/to/hex_buzz

# Run monitoring setup script
./monitoring/setup-monitoring.sh
```

This script will:
- Create notification channels (email, Slack)
- Enable log-based metrics
- Guide you through manual configuration steps

### 2. Install Flutter Dependencies

```bash
# Install Firebase Performance Monitoring and Crashlytics
flutter pub get
```

The app already includes:
- `firebase_performance: ^0.10.0+10` - Performance monitoring
- `firebase_crashlytics: ^4.1.5` - Crash reporting

### 3. Verify Configuration

```bash
# Check Firebase Performance is enabled
firebase apps:sdkconfig android

# Check Crashlytics is enabled
firebase crashlytics:symbols:upload --app=<your-app-id>
```

### 4. Create Alert Policies

Follow the guided steps in Cloud Console to create alerts based on `monitoring/alerting-config.yaml`.

## Monitoring Components

### Firebase Performance Monitoring

**What it monitors:**
- App startup time
- Screen rendering duration
- HTTP/HTTPS network request latency
- Custom traces for critical operations

**Configuration in app:**
```dart
// lib/main.dart
final performance = FirebasePerformance.instance;
await performance.setPerformanceCollectionEnabled(true);
```

**Key screens monitored:**
- `FrontScreen` - App entry point
- `LeaderboardScreen` - Critical for engagement
- `GameScreen` - Core gameplay
- `DailyChallengeScreen` - Daily engagement

**How to add custom traces:**
```dart
final trace = FirebasePerformance.instance.newTrace('leaderboard_load');
await trace.start();
// ... perform operation
await trace.stop();
```

**Viewing data:**
1. Firebase Console → Performance
2. Filter by screen/trace name
3. Analyze p50, p90, p99 latencies

### Firebase Crashlytics

**What it monitors:**
- Crash-free users percentage
- Fatal crashes
- Non-fatal exceptions
- Custom logs and keys

**Configuration in app:**
```dart
// lib/main.dart (release mode only)
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

**Custom logging:**
```dart
// Add breadcrumbs
await FirebaseCrashlytics.instance.log('User submitted score');

// Set custom keys
await FirebaseCrashlytics.instance.setCustomKey('level_id', levelId);
await FirebaseCrashlytics.instance.setCustomKey('user_id', userId);

// Record non-fatal errors
try {
  // risky operation
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
}
```

**Viewing data:**
1. Firebase Console → Crashlytics
2. View crash-free rate trends
3. Analyze crashes by device, OS version
4. Create issues from crashes

### Cloud Functions Monitoring

**What it monitors:**
- Function execution count
- Error rate and error types
- Execution duration (p50, p95, p99)
- Memory usage
- Cold start latency

**Functions monitored:**
- `onScoreUpdate` - Critical path for leaderboard
- `generateDailyChallenge` - Must run daily at 00:00 UTC
- `sendDailyChallengeNotifications` - User engagement
- `onUserCreated` - User onboarding
- `recomputeAllRanks` - Manual admin operation

**Viewing logs:**
```bash
# View all function logs
firebase functions:log

# View specific function
firebase functions:log --only onScoreUpdate

# Stream logs in real-time
firebase functions:log --only generateDailyChallenge --lines 100

# View logs in Cloud Console
# https://console.cloud.google.com/functions/list
```

**Key log patterns:**
```
✅ Good: "Updated user {userId} stars by {diff}"
✅ Good: "Generated daily challenge for {date} with level {id}"
⚠️  Warning: "Score not better than current"
❌ Error: "Error updating score: {error}"
❌ Error: "Error generating daily challenge: {error}"
```

### Firestore Monitoring

**What it monitors:**
- Document read/write/delete counts
- Query latency
- Composite index usage
- Quota consumption

**Collections monitored:**
- `users` - User profiles
- `leaderboard` - Global rankings
- `dailyChallenges` - Daily challenge data
- `scoreSubmissions` - Score submissions (trigger onScoreUpdate)
- `users/{userId}/levelProgress` - Per-user level progress

**Query performance:**
```bash
# View slow queries in Cloud Console
# https://console.cloud.google.com/firestore/databases/-default-/usage
```

**Index monitoring:**
- All required indexes are defined in `firestore.indexes.json`
- Missing indexes cause queries to fail
- Check Console for "Create Index" links in logs

### FCM (Firebase Cloud Messaging) Monitoring

**What it monitors:**
- Message send count (success/failure)
- Delivery rate
- Error types (invalid token, unregistered, etc.)
- Topic subscriber count

**Message types:**
- Daily challenge notifications (topic: `daily_challenge`)
- Rank change notifications (individual tokens)
- Re-engagement notifications (future)

**Viewing metrics:**
```bash
# Cloud Console → Cloud Messaging → Reports
# https://console.firebase.google.com/project/<project-id>/notification/reporting
```

**Common errors:**
- `INVALID_ARGUMENT`: Malformed message
- `UNREGISTERED`: Device token no longer valid (user uninstalled app)
- `SENDER_ID_MISMATCH`: Token from different Firebase project
- `QUOTA_EXCEEDED`: Daily FCM quota exceeded

## Alert Configuration

All alert configurations are defined in `monitoring/alerting-config.yaml`.

### Critical Alerts (PagerDuty)

These alerts require immediate response:

1. **Daily Challenge Generation Failure**
   - **Impact**: No daily challenge for users
   - **Response time**: < 1 hour
   - **Action**: Manually trigger or investigate

2. **Cloud Functions Complete Outage**
   - **Impact**: No score submissions, leaderboard updates
   - **Response time**: < 30 minutes
   - **Action**: Check Firebase status, review recent deployments

### High Priority Alerts (Slack + Email)

These alerts need attention within a few hours:

1. **High Cloud Functions Error Rate** (>5%)
2. **Firestore Quota Near Limit** (>80%)
3. **Low FCM Delivery Rate** (<95%)
4. **High App Crash Rate** (>1%)

### Medium Priority Alerts (Email)

These alerts can be addressed during business hours:

1. **High Cloud Functions Latency** (>10s p95)
2. **High Firestore Query Latency** (>2s p95)
3. **Slow App Screen Rendering** (>1s p95)
4. **Budget Alert** (>80% of monthly budget)

### Creating Alerts in Cloud Console

#### Example: Cloud Functions Error Rate Alert

1. Go to [Cloud Monitoring Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Click **Create Policy**
3. Click **Select a metric**
4. Select:
   - Resource type: `Cloud Function`
   - Metric: `Execution count`
5. Add filter: `status != "ok"`
6. Set aggregation:
   - Rolling window: 5 minutes
   - Aligner: Rate
   - Reducer: Sum
7. Set condition:
   - Threshold: 0.05 (5% error rate)
   - For: 5 minutes
8. Add notification channel
9. Add documentation (from alerting-config.yaml)
10. Save policy

#### Example: Firestore Quota Alert

1. Go to [Cloud Monitoring Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Click **Create Policy**
3. Click **Select a metric**
4. Select:
   - Resource type: `Firestore Instance`
   - Metric: `Document read count`
5. Set aggregation:
   - Rolling window: 1 hour
   - Aligner: Rate
   - Reducer: Sum
6. Set condition:
   - Threshold: 80% of daily quota
   - For: 15 minutes
7. Add notification channels
8. Save policy

## Dashboards

### Main Production Dashboard

Create a comprehensive dashboard with these widgets:

#### 1. Cloud Functions Health

**Widget type**: Line chart
**Metrics**:
- Cloud Function execution count (by function)
- Cloud Function error count (by function)
- Cloud Function execution time (p95)

**Time range**: Last 24 hours

#### 2. Firestore Operations

**Widget type**: Stacked area chart
**Metrics**:
- Document reads
- Document writes
- Document deletes

**Time range**: Last 24 hours

#### 3. Active Users

**Widget type**: Scorecard
**Metric**: Active users (last 24 hours)
**Source**: Firebase Analytics

#### 4. App Performance

**Widget type**: Multiple scorecards
**Metrics**:
- Crash-free rate (%)
- Average screen render time (ms)
- App startup time (ms)

#### 5. FCM Delivery

**Widget type**: Line chart
**Metrics**:
- Successful message sends
- Failed message sends
- Delivery rate (%)

**Time range**: Last 7 days

#### 6. Leaderboard Performance

**Widget type**: Heatmap
**Metric**: Firestore query latency
**Filter**: Collection = `leaderboard`
**Aggregation**: p95

**Time range**: Last 24 hours

#### 7. Daily Challenge Metrics

**Widget type**: Table
**Metrics**:
- Challenge generation success count
- Notification send count
- User participation count

**Time range**: Last 30 days

### Creating Dashboard in Cloud Console

1. Go to [Cloud Monitoring Dashboards](https://console.cloud.google.com/monitoring/dashboards)
2. Click **Create Dashboard**
3. Name it "HexBuzz Production Overview"
4. Click **Add Chart**
5. Configure each widget as described above
6. Arrange widgets in logical sections
7. Save dashboard

## Testing Alerts

### Test Methodology

Always test alerts in a **staging environment** first!

### 1. Test Cloud Functions Error Alert

```bash
# Temporarily modify function to throw error
# In functions/src/index.ts

export const testErrorAlert = functions.https.onCall(async () => {
  throw new Error('Test error for alert validation');
});

# Deploy
firebase deploy --only functions:testErrorAlert

# Trigger multiple times to exceed threshold
for i in {1..10}; do
  firebase functions:call testErrorAlert
done

# Wait 5-10 minutes for alert to fire
# Check email/Slack for notification
```

### 2. Test Firestore Quota Alert

```bash
# Create script to generate high read volume
# test-firestore-quota.js

const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function generateReads() {
  for (let i = 0; i < 10000; i++) {
    await db.collection('leaderboard').limit(100).get();
  }
}

generateReads();

# Run script
node test-firestore-quota.js

# Monitor quota in Firebase Console
# Alert should fire when approaching 80% of quota
```

### 3. Test FCM Delivery Alert

```bash
# Send notifications with invalid tokens

const admin = require('firebase-admin');
admin.initializeApp();

async function testFailedNotifications() {
  const invalidTokens = Array(20).fill('invalid-token');

  for (const token of invalidTokens) {
    try {
      await admin.messaging().send({
        token: token,
        notification: { title: 'Test', body: 'Test' }
      });
    } catch (error) {
      console.log('Expected error:', error.code);
    }
  }
}

testFailedNotifications();

# Alert should fire when delivery rate drops below 95%
```

### 4. Test App Crash Alert

```dart
// Add temporary crash trigger in app

ElevatedButton(
  onPressed: () {
    // Test non-fatal error
    FirebaseCrashlytics.instance.recordError(
      Exception('Test exception for monitoring'),
      StackTrace.current,
      fatal: false,
    );

    // Test fatal crash (use carefully!)
    // throw Exception('Test fatal crash');
  },
  child: Text('Test Crashlytics'),
)
```

### Verify Alert Delivery

After triggering test conditions:

1. Check email inbox for alert notifications
2. Check Slack channel for alert messages
3. Verify alert appears in Cloud Console:
   - Go to [Alerting](https://console.cloud.google.com/monitoring/alerting)
   - View "Incidents" tab
   - Confirm test alert is listed
4. Acknowledge and close test alert

## Incident Response

### General Incident Response Process

1. **Detect**: Alert fires → Notification received
2. **Acknowledge**: Responder acknowledges alert in Cloud Console
3. **Assess**: Review logs, metrics, recent changes
4. **Mitigate**: Implement immediate fix or rollback
5. **Resolve**: Verify issue is resolved, close alert
6. **Post-mortem**: Document incident, root cause, prevention

### Common Incidents and Response

#### Incident: Daily Challenge Generation Failed

**Symptoms:**
- Alert: "generateDailyChallenge scheduled function failure"
- Users report no daily challenge
- Daily challenge document missing in Firestore

**Immediate actions:**
1. Check Cloud Functions logs:
   ```bash
   firebase functions:log --only generateDailyChallenge --lines 100
   ```
2. Identify error cause (quota, network, code bug)
3. Manually create daily challenge if needed:
   ```bash
   # Use Firebase Console to create document:
   # Collection: dailyChallenges
   # Document ID: YYYY-MM-DD (today's date)
   # Fields: { id, date, levelId, completionCount: 0, createdAt }
   ```
4. Manually trigger notifications:
   ```bash
   firebase functions:call sendDailyChallengeNotifications
   ```
5. Monitor for successful execution tomorrow

**Root cause analysis:**
- Check scheduler configuration (should be "0 0 * * *")
- Verify timezone is UTC
- Check Firestore write quota
- Review recent code changes

#### Incident: High Cloud Functions Error Rate

**Symptoms:**
- Alert: "Cloud Functions error rate >5%"
- Users report leaderboard not updating
- Score submissions failing

**Immediate actions:**
1. Identify failing function:
   ```bash
   firebase functions:log | grep -i "error"
   ```
2. Check Firestore status: https://status.firebase.google.com/
3. If Firestore quota exceeded:
   - Review quota usage in Console
   - Identify heavy read/write sources
   - Implement rate limiting if needed
   - Consider upgrading plan
4. If code bug:
   - Review recent deployments
   - Rollback to previous version if necessary:
     ```bash
     # List previous versions
     gcloud functions list
     # Rollback specific function
     gcloud functions deploy onScoreUpdate --source=<previous-commit>
     ```

#### Incident: Firestore Quota Exceeded

**Symptoms:**
- Alert: "Firestore quota near limit"
- Queries failing with RESOURCE_EXHAUSTED error
- Users seeing error messages

**Immediate actions:**
1. Identify quota type (reads, writes, deletes):
   ```
   # Cloud Console → Firestore → Usage
   ```
2. Find source of excessive operations:
   - Check leaderboard cache TTL (should be 5 minutes)
   - Review recomputeRanks() frequency
   - Check for infinite loops or bugs
3. Temporary mitigation:
   - Increase cache TTL to 10 minutes
   - Disable non-critical features temporarily
   - Upgrade to higher quota tier
4. Long-term fixes:
   - Optimize queries (add indexes)
   - Implement better caching
   - Change recomputeRanks to scheduled batch job
   - Add rate limiting

#### Incident: High App Crash Rate

**Symptoms:**
- Alert: "App crash-free rate <99%"
- Crashlytics shows spike in crashes
- User reviews mention crashes

**Immediate actions:**
1. Open Crashlytics dashboard:
   ```
   https://console.firebase.google.com/project/<project-id>/crashlytics
   ```
2. Identify most common crash:
   - Group by crash type
   - Note affected OS versions/devices
   - Review stack traces
3. Assess severity:
   - What % of users affected?
   - Is it on critical path (e.g., app startup)?
   - Is workaround available?
4. If critical crash:
   - Develop and test hotfix
   - Deploy new version ASAP
   - Consider A/B rollout (gradual rollout)
5. If non-critical:
   - Add to backlog
   - Fix in next release
   - Monitor for increase

### Escalation Path

| Severity | Response Time | Escalate To |
|----------|--------------|-------------|
| P0 - Critical (app down) | 15 minutes | On-call engineer |
| P1 - High (major feature broken) | 1 hour | Team lead |
| P2 - Medium (performance degraded) | 4 hours | During business hours |
| P3 - Low (minor issue) | 24 hours | Regular sprint work |

## Cost Optimization

Monitor Firebase/GCP costs to stay within budget.

### Current Cost Breakdown (Estimated)

Based on **1,000 daily active users**:

| Service | Monthly Cost | Main Drivers |
|---------|-------------|--------------|
| Firestore | $50-100 | Reads (leaderboard), Writes (scores) |
| Cloud Functions | $20-40 | Invocations, Compute time |
| FCM | $0 | Free up to 1M messages/month |
| Cloud Storage | $5-10 | Level data, user avatars |
| Performance Monitoring | $0 | Free tier (< 100K sessions/month) |
| Crashlytics | $0 | Free |
| **Total** | **$75-150/month** | |

### Cost Optimization Strategies

#### 1. Optimize Firestore Reads

**Current:** Leaderboard cached for 5 minutes
**Optimization:** Increase to 10 minutes or cache until user action

```dart
// lib/data/firebase/firebase_leaderboard_repository.dart
static const _cacheTTL = Duration(minutes: 10); // Increased from 5
```

**Impact:** 50% reduction in leaderboard reads

#### 2. Optimize Rank Recomputation

**Current:** recomputeRanks() called on every score submission
**Problem:** With 1,000 users, reads 1,000 documents per submission

**Optimization:** Change to scheduled batch job

```typescript
// functions/src/index.ts

// Remove from onScoreUpdate:
// await recomputeRanks();

// Create new scheduled function:
export const recomputeRanksScheduled = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async () => {
    await recomputeRanks();
  });
```

**Impact:**
- Before: 1,000 reads × 1,000 submissions/day = 1M reads/day
- After: 1,000 reads × 144 runs/day = 144K reads/day
- **Savings: 85% reduction in reads**

#### 3. Implement Write Batching

**Current:** Individual writes for each score submission
**Optimization:** Batch multiple writes together

```typescript
// Batch writes in onScoreUpdate
const batch = db.batch();
batch.update(levelProgressRef, { ... });
batch.update(userRef, { ... });
batch.set(leaderboardRef, { ... }, { merge: true });
await batch.commit(); // 1 write operation instead of 3
```

**Impact:** 66% reduction in write operations

#### 4. Use Cloud Functions Min Instances (Production Only)

```typescript
// functions/src/index.ts
export const onScoreUpdate = functions
  .runWith({ minInstances: 1 })  // Keep 1 instance warm
  .firestore
  .document('scoreSubmissions/{submissionId}')
  .onCreate(async (snap) => { ... });
```

**Trade-off:**
- Faster response times (no cold starts)
- Higher cost ($5-10/month per instance)
- Only use for critical functions

#### 5. Monitor and Set Budget Alerts

Set up budget alerts at these thresholds:

- 50% of budget: Informational email
- 80% of budget: Warning email + Slack
- 90% of budget: Critical alert + review costs
- 100% of budget: Consider disabling non-essential features

### Cost Monitoring Queries

```bash
# View cost breakdown by service
gcloud billing accounts list
gcloud billing projects describe PROJECT_ID

# Export billing data to BigQuery for analysis
gcloud alpha billing accounts set-export-config ACCOUNT_ID \
  --dataset-id=billing_export \
  --project-id=PROJECT_ID
```

## Troubleshooting

### Performance Monitoring Not Showing Data

**Symptoms:**
- Firebase Performance Monitoring tab empty
- No traces or screen rendering data

**Solutions:**
1. Verify Performance Monitoring is enabled in app:
   ```dart
   final performance = FirebasePerformance.instance;
   await performance.setPerformanceCollectionEnabled(true);
   ```
2. Check Firebase Console settings:
   - Go to Performance Monitoring → Settings
   - Ensure data collection is enabled
3. Wait 24 hours for initial data to appear
4. Test with custom trace:
   ```dart
   final trace = FirebasePerformance.instance.newTrace('test_trace');
   await trace.start();
   await Future.delayed(Duration(seconds: 2));
   await trace.stop();
   ```

### Crashlytics Not Reporting Crashes

**Symptoms:**
- Crashlytics dashboard shows 100% crash-free (no crashes)
- Known crashes not appearing

**Solutions:**
1. Verify Crashlytics is enabled (release mode only):
   ```dart
   if (!kDebugMode) {
     FlutterError.onError =
       FirebaseCrashlytics.instance.recordFlutterFatalError;
   }
   ```
2. Check app is built in release mode:
   ```bash
   flutter build apk --release
   ```
3. Force a test crash:
   ```dart
   FirebaseCrashlytics.instance.crash(); // Test only!
   ```
4. Wait 5-10 minutes for crash report to upload
5. Check Firebase Console → Crashlytics

### Alerts Not Firing

**Symptoms:**
- Expected alert conditions met but no notification received

**Solutions:**
1. Verify alert policy is enabled:
   - Cloud Console → Monitoring → Alerting
   - Check policy status
2. Verify notification channels are configured:
   - Check email address is correct
   - Test Slack webhook
3. Check alert condition threshold:
   - May need to adjust threshold
   - Verify aggregation window
4. Check incidents tab:
   - Alert may have fired but notification failed
5. Review notification channel logs:
   - Cloud Logging → search for "notification"

### High Cloud Functions Latency

**Symptoms:**
- Cloud Functions taking >10 seconds to execute
- Users report slow leaderboard updates

**Solutions:**
1. Identify slow function:
   ```bash
   firebase functions:log | grep "Function execution took"
   ```
2. Profile function execution:
   - Add timing logs in function code
   - Identify bottleneck (Firestore query, computation, etc.)
3. Optimize bottleneck:
   - **Slow query**: Add composite index
   - **Rank recomputation**: Change to scheduled job
   - **Cold start**: Enable min instances
4. Consider increasing function resources:
   ```typescript
   export const onScoreUpdate = functions
     .runWith({ memory: '2GB', timeoutSeconds: 60 })
     .firestore...
   ```

### Firestore Query Timeout

**Symptoms:**
- Firestore queries failing with DEADLINE_EXCEEDED error
- Leaderboard taking >10 seconds to load

**Solutions:**
1. Check if composite indexes are created:
   ```bash
   firebase deploy --only firestore:indexes
   ```
2. Verify indexes in Firebase Console:
   - Firestore → Indexes
   - Look for "Building" or "Error" status
3. Wait for index creation (can take 5-10 minutes)
4. Check query for missing indexes:
   - Look for console logs: "The query requires an index"
   - Click "Create Index" link
5. Optimize query:
   - Reduce limit (currently 50, consider 20)
   - Add pagination
   - Implement cursor-based pagination

### Budget Exceeded

**Symptoms:**
- Budget alert at 100%
- Services may be rate-limited or stopped

**Immediate actions:**
1. Review cost breakdown in Cloud Console:
   ```
   https://console.cloud.google.com/billing
   ```
2. Identify highest cost service
3. Implement immediate cost reductions:
   - Increase leaderboard cache TTL to 30 minutes
   - Change rank recomputation to once per hour
   - Disable non-essential notifications
4. Upgrade billing plan if within business projections
5. Implement aggressive rate limiting:
   - Max 1 score submission per user per minute
   - Max 1 leaderboard refresh per user per 5 minutes

## Appendix

### Useful Links

- [Firebase Console](https://console.firebase.google.com/)
- [Cloud Monitoring](https://console.cloud.google.com/monitoring)
- [Cloud Functions](https://console.cloud.google.com/functions)
- [Firestore](https://console.cloud.google.com/firestore)
- [Firebase Status](https://status.firebase.google.com/)
- [GCP Status](https://status.cloud.google.com/)

### CLI Commands Reference

```bash
# Firebase CLI
firebase login
firebase projects:list
firebase use PROJECT_ID
firebase deploy --only functions
firebase functions:log
firebase functions:log --only FUNCTION_NAME
firebase functions:call FUNCTION_NAME

# gcloud CLI
gcloud auth login
gcloud config set project PROJECT_ID
gcloud projects list
gcloud monitoring policies list
gcloud monitoring channels list
gcloud logging read "resource.type=cloud_function" --limit 50
gcloud logging read "severity>=ERROR" --limit 50 --format json

# Flutter
flutter pub get
flutter test
flutter build apk --release
flutter build ios --release
flutter build windows --release
```

### Monitoring Checklist

Use this checklist for regular monitoring reviews (weekly/monthly):

#### Weekly Checklist

- [ ] Review Cloud Functions error rate trend
- [ ] Check Firestore quota usage (reads/writes)
- [ ] Verify daily challenge is generating correctly
- [ ] Review top 5 Crashlytics issues
- [ ] Check FCM delivery rate
- [ ] Review any open incidents
- [ ] Verify alerts are firing correctly (test if needed)

#### Monthly Checklist

- [ ] Review performance trends (latency, crash rate)
- [ ] Analyze cost breakdown and trends
- [ ] Review SLO compliance (target vs actual)
- [ ] Update alert thresholds if needed
- [ ] Review and update dashboards
- [ ] Conduct alert drill (test critical alerts)
- [ ] Document any recurring issues
- [ ] Plan optimizations for next month

### Support Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| Firebase/GCP outage | [Firebase Status](https://status.firebase.google.com/) | N/A |
| Technical support | [Firebase Support](https://firebase.google.com/support) | 24-48 hours |
| Billing questions | [GCP Billing Support](https://cloud.google.com/billing/docs/how-to/get-support) | 24 hours |
| Critical production issue | On-call engineer (internal) | 15 minutes |

---

**Document Version:** 1.0
**Last Updated:** 2026-01-17
**Next Review:** 2026-02-17
