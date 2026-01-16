# Cloud Functions Deployment Guide

## Overview

This document provides instructions for deploying and testing the HexBuzz Cloud Functions for social and competitive features.

## Prerequisites

1. **Firebase CLI**: Install the Firebase CLI globally
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Project**: Create a Firebase project at https://console.firebase.google.com/

3. **Authentication**: Login to Firebase
   ```bash
   firebase login
   ```

4. **Project Configuration**: Initialize Firebase project
   ```bash
   # From the repository root directory
   firebase init

   # Or link to an existing project
   firebase use --add
   ```

   This will create a `.firebaserc` file with your project configuration.

## Build and Lint

Before deploying, always build and lint the functions:

```bash
cd functions
npm run lint        # Run ESLint
npm run build       # Compile TypeScript to JavaScript
```

All linting errors must be fixed before deployment.

## Deployment

### Deploy All Functions

```bash
# From the repository root
firebase deploy --only functions

# Or from the functions directory
npm run deploy
```

### Deploy Individual Functions

```bash
# Deploy only the score update trigger
firebase deploy --only functions:onScoreUpdate

# Deploy only the daily challenge generation
firebase deploy --only functions:generateDailyChallenge

# Deploy only the user creation trigger
firebase deploy --only functions:onUserCreated
```

## Testing Cloud Functions

### 1. Local Testing with Firebase Emulators

Start the Firebase emulators for local testing:

```bash
# From repository root
firebase emulators:start

# Or start only specific emulators
firebase emulators:start --only functions,firestore,auth
```

The emulators will run on:
- **Functions**: http://localhost:5001
- **Firestore**: http://localhost:8080
- **Auth**: http://localhost:9099
- **Emulator UI**: http://localhost:4000

Configure your Flutter app to use emulators for testing (see app configuration).

### 2. Testing Individual Functions

#### Test onScoreUpdate Trigger

**Trigger**: Automatically called when a document is created in `scoreSubmissions` collection.

**Test via Firestore**:
1. Open Firebase Console → Firestore
2. Navigate to `scoreSubmissions` collection
3. Add a new document with:
   ```json
   {
     "userId": "test-user-id",
     "levelId": "level-10",
     "stars": 3,
     "time": 45000,
     "createdAt": <server_timestamp>
   }
   ```
4. Check logs to verify function execution
5. Verify `users` and `leaderboard` collections are updated

**Expected Behavior**:
- User's total stars incremented
- Leaderboard entry updated
- Ranks recomputed for all users
- Notification sent if rank changed by ±10 positions

#### Test generateDailyChallenge Scheduled Function

**Trigger**: Runs automatically at 00:00 UTC daily.

**Manual Trigger via Cloud Functions Console**:
1. Open Firebase Console → Functions
2. Find `generateDailyChallenge` function
3. Click "..." → "Test function"
4. Check logs for successful execution

**Test via HTTP Call** (during development):
```bash
# First deploy the sendDailyChallengeNotifications callable function
firebase deploy --only functions:sendDailyChallengeNotifications

# Then call it from your app or using curl
curl -X POST \
  https://us-central1-<PROJECT_ID>.cloudfunctions.net/sendDailyChallengeNotifications \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/json"
```

**Expected Behavior**:
- New document created in `dailyChallenges` with today's date (YYYY-MM-DD)
- Document contains random level ID (10-30)
- Notification sent to all users subscribed to `daily_challenge` topic
- Idempotent: Running twice doesn't create duplicates

#### Test onUserCreated Trigger

**Trigger**: Automatically called when a new user document is created.

**Test via Firestore**:
1. Create a new user document in `users` collection:
   ```json
   {
     "uid": "new-user-123",
     "email": "test@example.com",
     "displayName": "Test User",
     "photoURL": "https://example.com/photo.jpg",
     "deviceToken": "test-device-token",
     "createdAt": <server_timestamp>
   }
   ```
2. Check logs to verify function execution
3. Verify leaderboard entry created with 0 stars

**Expected Behavior**:
- New document created in `leaderboard` collection
- Initial rank set to 999999
- Total stars set to 0
- User subscribed to `daily_challenge` FCM topic (if device token exists)

#### Test recomputeAllRanks Callable Function

**Purpose**: Manual admin function to recompute all ranks.

**Test via Firebase Console**:
1. Open Firebase Console → Functions
2. Find `recomputeAllRanks` function
3. Click "..." → "Test function"
4. Provide auth context (must be authenticated user)

**Expected Behavior**:
- All users in `leaderboard` collection get updated ranks
- Ranks assigned based on total stars (descending order)
- Batch operation completes successfully

### 3. Monitoring Function Logs

#### View Logs via Firebase Console

1. Open Firebase Console → Functions
2. Click on any function name
3. Go to "Logs" tab
4. Filter by severity, time range, or search text

#### View Logs via CLI

```bash
# View all function logs
firebase functions:log

# View logs for specific function
firebase functions:log --only onScoreUpdate

# Follow logs in real-time
firebase functions:log --follow

# Filter by severity
firebase functions:log --severity error
```

#### Structured Logging

All functions use structured logging with these patterns:
- **Success**: `console.log("Action completed", { userId, data })`
- **Errors**: `console.error("Error message", error)`
- **Info**: `console.log("Info message")`

## Setting Up Monitoring and Alerts

### 1. Cloud Monitoring Alerts

Set up alerts for function errors:

1. Open Google Cloud Console → Monitoring → Alerting
2. Create alert policy with:
   - **Resource**: Cloud Function
   - **Metric**: Function executions with error status
   - **Condition**: Count > 10 in 5 minutes
   - **Notification**: Email/Slack/PagerDuty

### 2. Firebase Performance Monitoring

Already integrated in the Flutter app. Monitor function performance:

1. Open Firebase Console → Performance
2. View function execution times
3. Set up alerts for slow function executions

### 3. Budget Alerts

Set up billing alerts to avoid unexpected costs:

1. Open Google Cloud Console → Billing → Budgets & alerts
2. Create budget for Cloud Functions
3. Set alerts at 50%, 75%, 90%, 100% of budget

## Function Costs and Optimization

### Invocation Counts (Estimated)

- **onScoreUpdate**: ~1000/day (depends on user activity)
- **generateDailyChallenge**: 1/day
- **onUserCreated**: ~50/day (new user signups)
- **Notification triggers**: Variable

### Cost Optimization Tips

1. **Use batched writes** in rank recomputation (already implemented)
2. **Cache leaderboard data** client-side to reduce function calls
3. **Limit notification fanout** by using FCM topics instead of individual tokens
4. **Set function memory** appropriately (default: 256MB, increase if needed)
5. **Use Cloud Scheduler** for daily challenge generation (already implemented)

### Monitoring Costs

View function costs:
1. Open Google Cloud Console → Billing → Reports
2. Filter by service: Cloud Functions
3. Group by SKU to see invocations, compute time, etc.

## Security Considerations

### Firestore Security Rules

All functions run with admin privileges, but Firestore security rules still apply to client access:

- Users can read their own data and leaderboards
- Users can write to `scoreSubmissions` (validated by rules)
- Daily challenges are read-only for clients
- Admin operations require authentication check in callable functions

### Authentication

- All callable functions check `context.auth` for authentication
- Trigger functions don't need auth (protected by Firestore rules)
- Use Firebase Auth ID tokens for HTTP calls

## Troubleshooting

### Function Deploy Fails

**Issue**: `Error: Failed to deploy functions`

**Solutions**:
1. Check TypeScript compilation: `npm run build`
2. Check linting: `npm run lint`
3. Verify Firebase project selected: `firebase use`
4. Check IAM permissions in Google Cloud Console

### Function Times Out

**Issue**: Function exceeds timeout (default: 60s)

**Solutions**:
1. Increase timeout in function configuration
2. Optimize queries (use indexes)
3. Use batched writes for bulk operations
4. Consider background functions for long operations

### Function Logs Show Errors

**Issue**: Functions execute but show errors in logs

**Solutions**:
1. Check error messages for details
2. Verify Firestore indexes exist (check console warnings)
3. Test with emulators locally
4. Check function permissions in IAM
5. Verify FCM tokens are valid for notifications

### Rank Recomputation Slow

**Issue**: `recomputeRanks()` takes too long

**Solutions**:
1. Already using batched writes (500 operations per batch max)
2. Consider pagination if user count > 10,000
3. Use Cloud Tasks for async processing if needed
4. Increase function memory allocation

## Next Steps

After deployment:

1. ✅ Verify all functions deployed successfully
2. ✅ Test each function with sample data
3. ✅ Set up monitoring and alerts
4. ✅ Configure budget alerts
5. ✅ Monitor logs for errors
6. ✅ Test notification delivery end-to-end
7. ✅ Verify scheduled function runs daily

## Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
