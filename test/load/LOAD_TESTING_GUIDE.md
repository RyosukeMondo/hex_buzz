# Comprehensive Load Testing Guide for HexBuzz

## Table of Contents

1. [Overview](#overview)
2. [Architecture & System Under Test](#architecture--system-under-test)
3. [Performance Requirements & SLOs](#performance-requirements--slos)
4. [Test Environment Setup](#test-environment-setup)
5. [Test Scenarios](#test-scenarios)
6. [Running Load Tests](#running-load-tests)
7. [Analyzing Results](#analyzing-results)
8. [Performance Optimization](#performance-optimization)
9. [Troubleshooting](#troubleshooting)
10. [CI/CD Integration](#cicd-integration)

---

## Overview

This comprehensive load testing suite validates that HexBuzz's Firebase Cloud Functions and Firestore operations can handle production-level traffic and scale appropriately.

### Goals

- **Validate scalability**: Ensure system handles 1000+ concurrent users
- **Identify bottlenecks**: Find performance issues before production
- **Establish baselines**: Document expected performance characteristics
- **Prevent regressions**: Catch performance degradation in CI/CD
- **Cost estimation**: Understand Firebase costs at scale

### Test Coverage

| Component | Operations Tested | Target Users |
|-----------|------------------|--------------|
| Score Submission | onScoreUpdate trigger, rank computation | 1000+ |
| Leaderboard | Query performance, pagination | 500+ |
| Daily Challenge | Generation, completions, leaderboards | 800+ |
| Mixed Workload | Realistic user behavior patterns | 1000+ |

---

## Architecture & System Under Test

### Firebase Services

```
┌─────────────────────────────────────────────────────────────┐
│                    HexBuzz Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │ Flutter App  │───────▶│   Firebase   │                  │
│  │   (Client)   │        │     Auth     │                  │
│  └──────────────┘        └──────────────┘                  │
│         │                        │                          │
│         │                        ▼                          │
│         │                ┌──────────────┐                  │
│         └───────────────▶│  Firestore   │                  │
│                          │   Database   │                  │
│                          └──────────────┘                  │
│                                  │                          │
│                                  │ Triggers                 │
│                                  ▼                          │
│                          ┌──────────────┐                  │
│                          │    Cloud     │                  │
│                          │  Functions   │                  │
│                          └──────────────┘                  │
│                                  │                          │
│                                  ▼                          │
│                          ┌──────────────┐                  │
│                          │     FCM      │                  │
│                          │(Notifications)│                 │
│                          └──────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Collections & Data Model

**users**: User profiles and authentication data
```json
{
  "uid": "string",
  "displayName": "string",
  "email": "string",
  "totalStars": "number",
  "rank": "number",
  "createdAt": "timestamp"
}
```

**leaderboard**: Global rankings
```json
{
  "userId": "string",
  "username": "string",
  "totalStars": "number",
  "rank": "number",
  "updatedAt": "timestamp"
}
```

**scoreSubmissions**: Individual level completions (triggers Cloud Function)
```json
{
  "userId": "string",
  "levelId": "number",
  "stars": "number",
  "time": "number",
  "submittedAt": "timestamp"
}
```

**dailyChallenges**: Daily challenge definitions
```json
{
  "id": "YYYY-MM-DD",
  "levelId": "number",
  "level": "object",
  "completionCount": "number",
  "completions": [subcollection]
}
```

### Cloud Functions

1. **onScoreUpdate**: Triggered on score submission
   - Updates user's total stars
   - Recomputes leaderboard ranks
   - Sends rank change notifications
   - **Bottleneck risk**: Rank recomputation on every submission

2. **generateDailyChallenge**: Scheduled daily at 00:00 UTC
   - Generates or selects daily challenge level
   - Stores in Firestore

3. **onUserCreated**: Triggered on new user
   - Initializes leaderboard entry
   - Subscribes to notification topics

---

## Performance Requirements & SLOs

### Service Level Objectives

| Metric | Target (P95) | Critical (P99) | Measurement |
|--------|-------------|----------------|-------------|
| **Score Submission** | < 2s | < 5s | Time from submission to acknowledgment |
| **Leaderboard Query** | < 2s | < 3s | Time to retrieve top 50 players |
| **Daily Challenge Load** | < 3s | < 5s | Time to fetch challenge and submit completion |
| **Notification Delivery** | > 95% success | > 90% minimum | FCM delivery confirmation |
| **Error Rate** | < 1% | < 5% maximum | Failed operations / total operations |
| **Concurrent Users** | 1000+ | 500 minimum | Simultaneous active users |

### Firestore Quotas (Free Tier)

- **Document Reads**: 50,000 / day
- **Document Writes**: 20,000 / day
- **Document Deletes**: 20,000 / day

### Estimated Load Capacity

Based on requirements:
- **Peak concurrent users**: 1,000
- **Operations per user per minute**: ~5 (3 reads, 2 writes)
- **Total operations per minute**: 5,000
- **Daily operations (1 hour peak)**: 300,000

---

## Test Environment Setup

### Option 1: Firebase Emulator (Recommended for Development)

**Advantages:**
- ✅ Free - unlimited operations
- ✅ Fast - no network latency
- ✅ Reproducible - consistent environment
- ✅ Safe - no production impact

**Setup:**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators from project root
firebase emulators:start

# In another terminal, run tests
cd test/load
npm install
npm run test:all -- --emulator
```

### Option 2: Firebase Staging Project

**Advantages:**
- ✅ Real infrastructure - matches production
- ✅ Cloud Functions - tests actual triggers
- ✅ Network conditions - realistic latency

**Requirements:**
- Dedicated staging Firebase project (DO NOT use production!)
- Service account key with Firestore permissions
- Budget allocation for Firestore operations

**Setup:**

```bash
# 1. Create staging project in Firebase Console
# 2. Download service account key

cd test/load
npm install

# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"

# Run tests
npm run test:all -- --firebase-project hexbuzz-staging
```

### Option 3: CI/CD Pipeline

Automated testing in GitHub Actions with Firebase Emulator.

```yaml
# .github/workflows/load-test.yml
name: Load Tests

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday 2 AM
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Start Firebase Emulator
        run: |
          firebase emulators:start --only firestore,functions &
          sleep 10

      - name: Install test dependencies
        working-directory: test/load
        run: npm install

      - name: Run load tests
        working-directory: test/load
        run: |
          npm run test:score-submission -- --users 100 --duration 60 --emulator
          npm run test:leaderboard -- --users 100 --emulator
          npm run test:daily-challenge -- --users 200 --emulator

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: load-test-results
          path: test/load/reports/
```

---

## Test Scenarios

### 1. Score Submission Load Test

**Scenario**: Concurrent users submitting level completion scores

**What it tests:**
- Firestore write performance
- Cloud Function trigger reliability
- Rank recomputation scalability
- Notification delivery

**Command:**
```bash
npm run test:score-submission -- --users 1000 --duration 60 --ramp-up 10
```

**Expected behavior:**
- P95 latency < 2s
- No Firestore quota errors
- Ranks correctly updated
- Notifications sent for significant rank changes (±10)

**Potential issues:**
- Rank recomputation bottleneck (recomputes ALL ranks on every submission)
- Write conflicts with concurrent submissions
- Function timeout (default 60s)

### 2. Leaderboard Query Load Test

**Scenario**: Users browsing and paginating through leaderboard

**What it tests:**
- Firestore query performance
- Composite index efficiency
- Pagination with large datasets
- Read scalability

**Command:**
```bash
npm run test:leaderboard -- --users 500 --queries-per-user 10
```

**Expected behavior:**
- P95 latency < 2s
- Consistent performance across pages
- Efficient index usage
- Low read operation count

**Potential issues:**
- Missing composite indexes
- Slow queries without proper ordering
- Excessive document reads
- Poor pagination performance

### 3. Daily Challenge Load Test

**Scenario**: Mass completion of daily challenge at peak time (e.g., morning)

**What it tests:**
- Challenge generation reliability
- Concurrent completion submissions
- Leaderboard updates under load
- Subcollection query performance

**Command:**
```bash
npm run test:daily-challenge -- --users 800 --concurrent 100
```

**Expected behavior:**
- Challenge generation < 1s
- P95 completion submission < 3s
- Completion counter accurate
- Leaderboard sorted correctly

**Potential issues:**
- Write conflicts on completion counter
- Subcollection query slowness
- Race conditions in score updates

### 4. Concurrent Users (Mixed Workload)

**Scenario**: Realistic user behavior with varied operations

**What it tests:**
- System stability under mixed load
- Operation priority and throttling
- Resource utilization
- Error rate under stress

**Command:**
```bash
npm run test:concurrent -- --users 1000 --duration 300 --ramp-up 30
```

**Operation mix:**
- 40% leaderboard queries (read-heavy)
- 30% score submissions (write-heavy)
- 15% daily challenge views (moderate)
- 15% daily challenge completions (intensive)

**Expected behavior:**
- Overall error rate < 1%
- Stable throughput
- No cascading failures
- Graceful degradation if overloaded

---

## Running Load Tests

### Quick Start

```bash
cd test/load
npm install

# Test with emulator (recommended for first run)
npm run test:score-submission -- --users 100 --emulator --duration 30

# Test with staging project
npm run test:leaderboard -- --users 500 --firebase-project hexbuzz-staging
```

### Progressive Load Testing

Start small and gradually increase load:

```bash
# Phase 1: Baseline (10 users)
npm run test:concurrent -- --users 10 --duration 60 --emulator

# Phase 2: Light load (100 users)
npm run test:concurrent -- --users 100 --duration 120 --emulator

# Phase 3: Moderate load (500 users)
npm run test:concurrent -- --users 500 --duration 180

# Phase 4: Target load (1000 users)
npm run test:concurrent -- --users 1000 --duration 300

# Phase 5: Stress test (2000 users)
npm run test:concurrent -- --users 2000 --duration 180
```

### Production-Like Load Test

**IMPORTANT**: Use dedicated staging project, NOT production!

```bash
# Full test suite with production-like load
export FIREBASE_PROJECT=hexbuzz-staging
export GOOGLE_APPLICATION_CREDENTIALS=./staging-key.json

# Test 1: Score submissions (high write load)
npm run test:score-submission -- \
  --users 1000 \
  --duration 180 \
  --ramp-up 30 \
  --firebase-project $FIREBASE_PROJECT

# Test 2: Leaderboard queries (high read load)
npm run test:leaderboard -- \
  --users 500 \
  --queries-per-user 20 \
  --firebase-project $FIREBASE_PROJECT

# Test 3: Daily challenge (peak morning load)
npm run test:daily-challenge -- \
  --users 800 \
  --concurrent 200 \
  --firebase-project $FIREBASE_PROJECT

# Test 4: Mixed workload (sustained load)
npm run test:concurrent -- \
  --users 1000 \
  --duration 600 \
  --ramp-up 60 \
  --firebase-project $FIREBASE_PROJECT \
  --report ./reports/production-test-$(date +%Y%m%d).json
```

---

## Analyzing Results

### Test Report Structure

```json
{
  "testName": "score-submission",
  "timestamp": "2026-01-17T12:00:00.000Z",
  "configuration": {
    "users": 1000,
    "duration": 180,
    "rampUp": 30
  },
  "totalOperations": 15000,
  "successfulOperations": 14850,
  "failedOperations": 150,
  "throughput": 83.33,
  "latencyStats": {
    "min": 245,
    "max": 8420,
    "mean": 1832,
    "median": 1650,
    "p95": 3200,
    "p99": 5100,
    "stdDev": 1024
  },
  "sloValidation": {
    "passed": false,
    "violations": [
      {
        "metric": "P99 Latency",
        "expected": 5000,
        "actual": 5100,
        "severity": "critical"
      }
    ]
  }
}
```

### Key Metrics to Monitor

#### 1. Latency Distribution

```
Good:        Bad:
P50: 1.2s    P50: 3.5s
P95: 2.1s    P95: 8.2s
P99: 3.8s    P99: 15.4s
```

**What to look for:**
- ✅ Tight distribution (low std deviation)
- ✅ P99 < 2x P95
- ❌ Wide distribution (high std deviation)
- ❌ Long tail (P99 >> P95)

#### 2. Throughput

```
Operations per second: 83.33 ops/s
Target: > 50 ops/s ✅
```

**What to look for:**
- ✅ Consistent throughput over time
- ✅ Linear scaling with users
- ❌ Throughput drops over time (resource exhaustion)
- ❌ Plateaus early (bottleneck)

#### 3. Error Rate

```
Total: 15,000 operations
Success: 14,850 (99.0%) ✅
Failed: 150 (1.0%)
```

**What to look for:**
- ✅ < 1% error rate
- ✅ Errors are transient (retryable)
- ❌ > 5% error rate (critical issue)
- ❌ Errors increase over time

### Firebase Console Monitoring

During tests, monitor:

**Firestore Usage:**
- Read operations per minute
- Write operations per minute
- Document count growth
- Index usage

**Cloud Functions:**
- Invocation count
- Execution time (P50, P95, P99)
- Error count and types
- Memory usage
- Active instances

**Firebase Authentication:**
- Sign-in success rate
- Active users

---

## Performance Optimization

### Common Bottlenecks & Solutions

#### 1. Slow Rank Recomputation

**Problem**: `recomputeRanks()` queries ALL leaderboard entries on every score submission

**Current implementation:**
```javascript
async function recomputeRanks(): Promise<void> {
  const leaderboardSnapshot = await db.collection("leaderboard")
    .orderBy("totalStars", "desc")
    .get(); // ❌ Reads ALL documents every time

  const batch = db.batch();
  let rank = 1;

  leaderboardSnapshot.forEach((doc) => {
    batch.update(doc.ref, { rank });
    rank++;
  });

  await batch.commit();
}
```

**Solutions:**

Option A: **Incremental rank updates** (best for low-medium scale)
```javascript
async function updateRankIncremental(userId, oldStars, newStars) {
  // Only update ranks of users in affected range
  const affectedUsers = await db.collection("leaderboard")
    .where("totalStars", ">=", Math.min(oldStars, newStars))
    .where("totalStars", "<=", Math.max(oldStars, newStars))
    .get();

  // Batch update only affected users
}
```

Option B: **Background rank computation** (best for high scale)
```javascript
// Don't recompute immediately - use stale ranks
// Schedule periodic batch job every 5 minutes to recompute all ranks
export const recomputeRanksPeriodic = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(recomputeRanks);
```

Option C: **Rank approximation** (best for very high scale)
```javascript
// Store approximate rank buckets instead of exact ranks
// "Top 10", "Top 100", "Top 1000", etc.
```

#### 2. Missing Composite Indexes

**Problem**: Slow queries due to missing indexes

**Symptoms:**
- Queries take > 5s
- Firebase Console shows "Composite index required" errors

**Solution:**
```bash
# Deploy composite indexes
firebase deploy --only firestore:indexes

# Verify in Firebase Console > Firestore > Indexes
```

Required indexes (in `firestore.indexes.json`):
```json
{
  "indexes": [
    {
      "collectionGroup": "leaderboard",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "totalStars", "order": "DESCENDING" },
        { "fieldPath": "updatedAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

#### 3. Firestore Write Conflicts

**Problem**: Concurrent updates to same document cause conflicts

**Symptoms:**
- Errors like "Document already exists" or "Transaction failed"
- Inconsistent counters

**Solution**: Use transactions
```javascript
await db.runTransaction(async (transaction) => {
  const challengeRef = db.collection('dailyChallenges').doc(dateStr);
  const challengeDoc = await transaction.get(challengeRef);

  const currentCount = challengeDoc.data().completionCount || 0;
  transaction.update(challengeRef, {
    completionCount: currentCount + 1
  });
});
```

#### 4. Cold Start Latency

**Problem**: First request to Cloud Function after idle period is slow

**Symptoms:**
- P99 latency >> P95 latency
- Sporadic slow requests

**Solution**: Keep functions warm
```javascript
// Scheduled function to ping and keep warm
export const keepWarm = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    // No-op to keep function warm
    console.log('Keep-alive ping');
  });
```

---

## Troubleshooting

### Error: "PERMISSION_DENIED"

**Cause**: Firestore security rules blocking operation

**Solution:**
1. Check security rules in `firestore.rules`
2. Verify service account has `datastore.owner` role
3. For emulator, ensure emulator is running

```bash
# Check emulator status
curl http://localhost:8080/

# View security rules
firebase firestore:rules
```

### Error: "QUOTA_EXCEEDED"

**Cause**: Exceeded Firebase free tier limits

**Solution:**
1. Use Firebase Emulator for testing (unlimited)
2. Upgrade to Blaze plan (pay-as-you-go)
3. Reduce test load or duration

```bash
# Check current quotas in Firebase Console
# Usage & billing > Quotas
```

### Error: "DEADLINE_EXCEEDED"

**Cause**: Operation took longer than timeout (default 60s for Cloud Functions)

**Solution:**
1. Optimize slow operations
2. Increase function timeout (max 540s)

```javascript
export const onScoreUpdate = functions
  .runWith({ timeoutSeconds: 300 }) // 5 minutes
  .firestore.document("scoreSubmissions/{submissionId}")
  .onCreate(/* ... */);
```

### Error: "RESOURCE_EXHAUSTED"

**Cause**: Too many concurrent operations

**Solution:**
1. Implement rate limiting on client
2. Add backoff and retry logic
3. Batch operations where possible

```javascript
// Client-side rate limiting
const rateLimiter = createRateLimiter(1000); // 1 request per second

await rateLimiter();
await submitScore(userId, stars);
```

### Slow Performance

**Diagnosis steps:**

1. **Check composite indexes**
```bash
firebase firestore:indexes
```

2. **Profile Cloud Functions**
   - View execution time in Firebase Console > Functions > Usage
   - Look for long-running operations

3. **Monitor Firestore operations**
   - Check read/write counts in Firebase Console > Firestore > Usage
   - Identify expensive queries

4. **Review function logs**
```bash
firebase functions:log --only onScoreUpdate
```

---

## CI/CD Integration

### GitHub Actions Workflow

Complete workflow for automated load testing:

```yaml
# .github/workflows/load-test.yml
name: Load Testing

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday 2 AM
  workflow_dispatch:
    inputs:
      users:
        description: 'Number of concurrent users'
        required: false
        default: '100'
      duration:
        description: 'Test duration (seconds)'
        required: false
        default: '60'

jobs:
  load-test:
    runs-on: ubuntu-latest
    timeout-minutes: 60

    strategy:
      matrix:
        test: [score-submission, leaderboard, daily-challenge, concurrent]

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: test/load/package-lock.json

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Start Firebase Emulator
        run: |
          cd functions
          npm install
          cd ..
          firebase emulators:start --only firestore,functions,auth --project demo-test &
          sleep 15

      - name: Install test dependencies
        working-directory: test/load
        run: npm ci

      - name: Run load test - ${{ matrix.test }}
        working-directory: test/load
        run: |
          USERS=${{ github.event.inputs.users || '100' }}
          DURATION=${{ github.event.inputs.duration || '60' }}

          case "${{ matrix.test }}" in
            score-submission)
              npm run test:score-submission -- --users $USERS --duration $DURATION --emulator
              ;;
            leaderboard)
              npm run test:leaderboard -- --users $USERS --emulator
              ;;
            daily-challenge)
              npm run test:daily-challenge -- --users $USERS --emulator
              ;;
            concurrent)
              npm run test:concurrent -- --users $USERS --duration $DURATION --emulator
              ;;
          esac

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: load-test-results-${{ matrix.test }}
          path: test/load/reports/
          retention-days: 30

      - name: Analyze results
        if: always()
        working-directory: test/load
        run: |
          # Parse latest report and check for SLO violations
          LATEST_REPORT=$(ls -t reports/*.json | head -1)
          echo "Analyzing report: $LATEST_REPORT"

          SLO_PASSED=$(node -p "JSON.parse(require('fs').readFileSync('$LATEST_REPORT')).sloValidation.passed")

          if [ "$SLO_PASSED" = "false" ]; then
            echo "❌ SLO violations detected!"
            exit 1
          else
            echo "✅ All SLOs passed"
          fi

      - name: Comment PR with results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const reports = fs.readdirSync('test/load/reports')
              .filter(f => f.endsWith('.json'))
              .map(f => JSON.parse(fs.readFileSync(`test/load/reports/${f}`)));

            const summary = reports.map(r => `
            ### ${r.testName}
            - Users: ${r.configuration.users}
            - Throughput: ${r.throughput.toFixed(2)} ops/s
            - P95 Latency: ${r.latencyStats.p95.toFixed(2)}ms
            - Error Rate: ${((r.failedOperations / r.totalOperations) * 100).toFixed(2)}%
            - SLOs: ${r.sloValidation.passed ? '✅ Passed' : '❌ Failed'}
            `).join('\n');

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Load Test Results\n\n${summary}`
            });

  notify-failure:
    needs: load-test
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Notify on failure
        run: |
          echo "Load tests failed! Check artifacts for details."
          # Add Slack/email notification here
```

### Pre-deployment Load Test

Run before deploying to production:

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      # ... setup steps ...

      - name: Run quick load test
        run: |
          cd test/load
          npm run test:concurrent -- --users 100 --duration 60 --emulator

      - name: Verify SLOs
        run: |
          # Fail deployment if SLOs not met
          # ... validation logic ...

  deploy:
    needs: load-test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Firebase
        run: firebase deploy --only functions,firestore
```

---

## Cost Estimation & Optimization

### Firestore Costs

Current pricing (as of 2026):
- Document reads: $0.06 per 100,000
- Document writes: $0.18 per 100,000
- Document deletes: $0.02 per 100,000
- Stored data: $0.18 per GB/month

### Cloud Functions Costs

- Invocations: $0.40 per million
- Compute time: $0.0000025 per GB-second
- Networking: $0.12 per GB

### Example: 1000-user, 5-minute test

```
Firestore operations:
- Users: 1000
- Operations per user: 30 (20 reads, 10 writes)
- Total reads: 20,000 → $0.012
- Total writes: 10,000 → $0.018

Cloud Functions:
- Invocations: 10,000 → $0.004
- Execution time: 10,000 × 2s × 256MB → $0.013

Total cost: ~$0.047 (< $0.05)
```

### Cost Optimization Tips

1. **Use Firebase Emulator** for development (free!)
2. **Batch operations** to reduce read/write counts
3. **Cache frequently accessed data** on client
4. **Optimize queries** to minimize document reads
5. **Use subcollections** to avoid reading large documents
6. **Schedule load tests** during off-peak hours
7. **Delete test data** after tests complete

---

## Next Steps

### After Running Load Tests

1. **Document baseline performance**: Record test results for future comparison
2. **Identify bottlenecks**: Prioritize optimization based on test results
3. **Set up monitoring**: Configure alerts for production metrics
4. **Schedule regular tests**: Add to CI/CD for regression testing
5. **Update SLOs**: Refine targets based on actual performance

### Performance Monitoring in Production

**Firebase Performance Monitoring:**
```javascript
// In Flutter app
import 'package:firebase_performance/firebase_performance.dart';

final trace = FirebasePerformance.instance.newTrace('leaderboard_query');
await trace.start();
// ... operation ...
await trace.stop();
```

**Cloud Functions Monitoring:**
```javascript
// Custom metrics
import * as monitoring from '@google-cloud/monitoring';

const client = new monitoring.MetricServiceClient();
await client.createTimeSeries({
  name: client.projectPath(projectId),
  timeSeries: [{
    metric: { type: 'custom.googleapis.com/rank_computation_time' },
    points: [{ interval: { endTime: { seconds: Date.now() / 1000 } }, value: { doubleValue: duration } }],
  }],
});
```

---

## Support & Resources

- **Firebase Documentation**: https://firebase.google.com/docs
- **Firestore Best Practices**: https://firebase.google.com/docs/firestore/best-practices
- **Cloud Functions Tips**: https://firebase.google.com/docs/functions/tips
- **Performance Monitoring**: https://firebase.google.com/docs/perf-mon

For questions or issues, check:
- Project documentation: `docs/`
- Security testing: `test/security/SECURITY_TESTING_REPORT.md`
- CI/CD setup: `.github/workflows/`
