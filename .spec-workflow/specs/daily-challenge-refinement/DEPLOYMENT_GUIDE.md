# Daily Challenge - Production Deployment Guide

## Task 22: Deploy Cloud Functions and Test in Production

### Pre-Deployment Checklist

Before deploying to production, verify:

- [x] All Cloud Functions exported in `functions/src/index.ts`
  - `scheduledDailyChallengeGenerator` ✅
  - `onDailyChallengeCreated` ✅
  - `manualGenerateChallenge` ✅
  - `manualSendNotification` ✅
  - `getDailyChallenge` ✅
  - `validateDailyChallengeCompletion` ✅

- [x] Firestore security rules updated and tested
  - One-attempt-per-day enforcement ✅
  - Stars validation (0-3) ✅
  - CompletionTimeMs validation (>1000ms) ✅
  - Prevent updates/deletes ✅

- [ ] All tests passing
  ```bash
  cd functions && npm test
  flutter test
  ```

- [ ] No TypeScript compilation errors
  ```bash
  cd functions && npm run build
  ```

- [ ] Environment variables configured (if any)
  ```bash
  firebase functions:config:get
  ```

---

## Deployment Steps

### Step 1: Deploy Firestore Security Rules

**Command**:
```bash
firebase deploy --only firestore:rules
```

**Verification**:
```bash
# Check deployed rules
firebase firestore:rules:get

# Test rules with Firebase Console → Firestore → Rules Playground
```

**Expected Output**:
```
✔  Deploy complete!
✔  firestore: deployed rules firestore.rules
```

**Rollback Plan**:
If rules cause issues, revert to previous version:
```bash
# View previous rules
git log -p firestore.rules

# Revert to previous commit
git revert <commit-hash>
firebase deploy --only firestore:rules
```

---

### Step 2: Deploy Cloud Functions

**Command**:
```bash
cd functions
npm run build  # Compile TypeScript
cd ..
firebase deploy --only functions
```

**Expected Output**:
```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (X.XX KB) for uploading
✔  functions: functions folder uploaded successfully

Functions to deploy:
- scheduledDailyChallengeGenerator
- onDailyChallengeCreated
- manualGenerateChallenge
- manualSendNotification
- getDailyChallenge
- validateDailyChallengeCompletion

i  functions: updating Node.js 18 function scheduledDailyChallengeGenerator...
i  functions: updating Node.js 18 function onDailyChallengeCreated...
i  functions: updating Node.js 18 function manualGenerateChallenge...
i  functions: updating Node.js 18 function manualSendNotification...
i  functions: updating Node.js 18 function getDailyChallenge...
i  functions: creating Node.js 18 function validateDailyChallengeCompletion...

✔  functions: all functions deployed successfully!
```

**Verification**:
```bash
# List deployed functions
firebase functions:list

# Check function details
firebase functions:config:get
```

**Alternative**: Deploy specific functions only:
```bash
# Deploy only new/updated functions
firebase deploy --only functions:validateDailyChallengeCompletion
firebase deploy --only functions:onDailyChallengeCreated
```

---

### Step 3: Verify Scheduled Function

**Check Schedule**:
```bash
# View scheduled functions in Firebase Console
# Functions → Cloud Scheduler
```

**Verify in Console**:
1. Navigate to **Cloud Scheduler** in Google Cloud Console
2. Find job: `firebase-schedule-scheduledDailyChallengeGenerator`
3. Verify schedule: `0 11 * * *` (11:00 UTC daily)
4. Check status: **Enabled**
5. View execution history for errors

**Manual Trigger** (for immediate testing):
```bash
# Trigger via HTTP
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/manualGenerateChallenge

# OR via Pub/Sub
gcloud pubsub topics publish firebase-schedule-scheduledDailyChallengeGenerator \
  --message="{}"
```

---

### Step 4: Test in Production

#### Test 1: Manual Challenge Generation

```bash
# Generate today's challenge
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/manualGenerateChallenge

# Expected response:
# {"success": true, "message": "Daily challenge generated successfully"}
```

**Verify in Firestore**:
```bash
firebase firestore:get dailyChallenges/$(date +%Y-%m-%d)
```

Expected document:
```json
{
  "id": "2026-01-30",
  "createdAt": "<timestamp>",
  "level": {
    "id": "<uuid>",
    "gridSize": 5,
    "difficulty": "medium",
    // ... level data
  },
  "completionCount": 0,
  "notificationSent": false  // Will become true after trigger
}
```

---

#### Test 2: Notification Sending

**Check `onDailyChallengeCreated` Trigger**:
1. Creating challenge should auto-trigger notification
2. Check Cloud Functions logs:
   ```bash
   firebase functions:log --only onDailyChallengeCreated --limit 10
   ```
3. Look for logs:
   - `daily_challenge_created`
   - Notification sending success/failure

**Manual Notification Trigger** (if needed):
```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/manualSendNotification \
  -H "Content-Type: application/json" \
  -d '{"challengeId": "2026-01-30"}'
```

**Verify Notification Delivery**:
- Check test device receives notification
- Tap notification → app opens at daily challenge screen
- Foreground notification shows SnackBar

---

#### Test 3: Completion Validation

**Setup**: Complete a daily challenge in the app, or test via Firebase Console.

**Test Duplicate Prevention**:
1. Complete challenge once (should succeed)
2. Attempt to complete again (should fail)

**Check Cloud Functions Logs**:
```bash
firebase functions:log --only validateDailyChallengeCompletion --limit 20
```

Expected logs:
- First completion: `daily_challenge_completion_validated` with rank
- Duplicate attempt: Error `already-exists: User has already completed this daily challenge`

**Verify Security Rules**:
Try to create duplicate entry via Firestore Console (should fail):
```
Collection: dailyChallenges/2026-01-30/entries
Document ID: <same userId>
Result: Permission denied (exists() check fails)
```

---

#### Test 4: Rank Calculation

**Steps**:
1. Have 3+ users complete the same challenge
2. Complete challenges with different stars/times:
   - User A: 3 stars, 45000ms
   - User B: 3 stars, 60000ms
   - User C: 2 stars, 30000ms

**Expected Ranks**:
1. User A: Rank 1 (3 stars, fastest)
2. User B: Rank 2 (3 stars, slower)
3. User C: Rank 3 (2 stars, even if faster time)

**Verify**:
```bash
firebase firestore:query dailyChallenges/2026-01-30/entries \
  --orderBy stars desc \
  --orderBy completionTimeMs asc
```

---

#### Test 5: Monitor Cloud Functions Metrics

**Firebase Console → Functions → Dashboard**:
- **Invocations**: Check call counts for each function
- **Execution time**: Verify < 10s for most functions
- **Memory usage**: Ensure within allocated limits
- **Errors**: Should be 0 or minimal

**Check Logs for Errors**:
```bash
# View all function logs
firebase functions:log --limit 100

# Filter for errors only
firebase functions:log --only functions --limit 50 | grep -i error

# Specific function logs
firebase functions:log --only validateDailyChallengeCompletion
```

**Expected**: No errors, all executions successful.

---

### Step 5: Load Testing (Optional)

Test with multiple concurrent users:

**Scenario**: 100 users complete challenge simultaneously

**Tools**:
- Firebase Performance Monitoring
- Cloud Functions metrics
- Load testing tool (e.g., Apache JMeter, k6)

**Sample Load Test Script** (k6):
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 100, // 100 virtual users
  duration: '30s',
};

export default function() {
  const url = 'https://REGION-PROJECT_ID.cloudfunctions.net/validateDailyChallengeCompletion';
  const payload = JSON.stringify({
    data: {
      dateId: '2026-01-30',
      stars: 3,
      completionTimeMs: Math.floor(Math.random() * 120000) + 30000
    }
  });
  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer <test-token>'
    }
  };

  const res = http.post(url, payload, params);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'has rank': (r) => JSON.parse(r.body).result.rank > 0
  });
}
```

**Run**:
```bash
k6 run load-test.js
```

**Expected Results**:
- 95%+ requests succeed
- p95 latency < 2 seconds
- No timeout errors
- Rank calculation accurate for all

---

### Step 6: Monitor Production

**First 24 Hours Monitoring**:
1. **Cloud Functions Logs**: Check every 2-4 hours for errors
   ```bash
   firebase functions:log --limit 100
   ```

2. **Firestore Usage**: Monitor read/write operations
   - Firebase Console → Firestore → Usage

3. **User Reports**: Check for bug reports or support tickets

4. **Scheduled Function**: Verify challenge created at 11:00 UTC
   - Check Firestore for new document
   - Verify notification sent

5. **Performance**: Monitor function execution times
   - Firebase Console → Functions → Metrics

**Set Up Alerts** (recommended):
- Cloud Functions errors > 10 in 1 hour
- Function execution time > 30s
- Daily challenge not created by 11:05 UTC
- Notification send failure rate > 5%

**Firebase Console → Alerts** or use **Cloud Monitoring**:
```yaml
# Example alert policy
displayName: "Daily Challenge Function Errors"
conditions:
  - displayName: "Error rate high"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_count" AND metric.label.status="error"'
      comparison: COMPARISON_GT
      thresholdValue: 10
      duration: 3600s
notificationChannels:
  - projects/PROJECT_ID/notificationChannels/CHANNEL_ID
```

---

## Rollback Plan

If critical issues occur:

### Immediate Actions
1. **Disable scheduled function** (stop new challenge generation):
   ```bash
   gcloud scheduler jobs pause firebase-schedule-scheduledDailyChallengeGenerator
   ```

2. **Revert Cloud Functions** to previous version:
   ```bash
   # View deployment history
   gcloud functions list

   # Rollback (if supported by hosting service)
   git revert <commit-hash>
   firebase deploy --only functions
   ```

3. **Revert Firestore rules** if causing permission issues:
   ```bash
   git revert <commit-hash>
   firebase deploy --only firestore:rules
   ```

### Communication
- Notify users of known issues via in-app message or social media
- Disable daily challenge screen temporarily if needed
- Post status update: "We're aware of an issue with daily challenges and are working on a fix."

---

## Post-Deployment Checklist

- [ ] All functions deployed successfully
- [ ] Firestore security rules deployed
- [ ] Scheduled function verified (Cloud Scheduler)
- [ ] Manual challenge generation tested
- [ ] Notification sending tested (foreground + background)
- [ ] Completion validation tested (success + duplicate prevention)
- [ ] Rank calculation verified with multiple users
- [ ] Security rules tested (read/write permissions)
- [ ] Cloud Functions logs reviewed (no errors)
- [ ] Performance metrics acceptable (< 10s execution time)
- [ ] Monitoring/alerts configured
- [ ] Rollback plan documented and tested
- [ ] Team notified of deployment
- [ ] User announcement prepared (if needed)

---

## Success Criteria

Deployment is successful when:
✅ Challenge auto-generates daily at 11:00 UTC
✅ Notifications sent to all users within 2 minutes
✅ Users can complete challenge (one attempt only)
✅ Duplicate completions blocked by rules + validation
✅ Rank calculation accurate and fast (< 2s)
✅ No errors in Cloud Functions logs
✅ Function execution times < 10s (p95)
✅ All tests passing in production

---

## Contact Information

**Deployment Lead**: _________________
**Date Deployed**: _________________
**Production URL**: https://REGION-PROJECT_ID.cloudfunctions.net/
**Firebase Project**: _________________
**Rollback Contact**: _________________

---

## Next Steps

After successful deployment:
1. Monitor for 24-48 hours
2. Mark Task 22 as completed in `tasks.md`
3. Proceed to Task 23 (Final verification and handoff)
4. Prepare release notes and user announcement
