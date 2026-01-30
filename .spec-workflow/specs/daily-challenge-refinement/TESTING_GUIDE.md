# Daily Challenge - Manual Testing Guide

## Task 18: Notification Flow Testing

### Prerequisites
- Firebase project configured
- Cloud Functions deployed
- Test device with FCM token registered
- Firebase Console access
- Firebase CLI installed

### Test Scenarios

#### Scenario 1: Scheduled Daily Challenge Creation & Notification
**Goal**: Verify that daily challenges are automatically generated and notifications sent

**Steps**:
1. Wait for scheduled trigger (11:00 UTC / 8:00 PM JST) OR manually trigger
2. Check Firebase Console → Firestore → `dailyChallenges` collection
3. Verify new document created with today's date ID
4. Check Cloud Functions logs for:
   - `daily_challenge_generation_started`
   - `daily_challenge_generated`
   - `daily_challenge_created` (Firestore trigger)
   - Notification sending logs

**Expected Results**:
- ✅ New challenge document exists with `notificationSent: true`
- ✅ No errors in Cloud Functions logs
- ✅ Notification appears on test device

**Verification Commands**:
```bash
# Check today's challenge exists
firebase firestore:get dailyChallenges/$(date +%Y-%m-%d)

# View Cloud Functions logs
firebase functions:log --only scheduledDailyChallengeGenerator
firebase functions:log --only onDailyChallengeCreated
```

---

#### Scenario 2: Manual Challenge Generation
**Goal**: Test manual trigger for challenge generation

**Steps**:
1. Run manual generation function:
   ```bash
   curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/manualGenerateChallenge
   ```
2. Check response: `{"success": true, "message": "Daily challenge generated successfully"}`
3. Verify challenge document in Firestore
4. Check notification delivery

**Expected Results**:
- ✅ HTTP 200 response
- ✅ Challenge document created
- ✅ Notification sent automatically via `onDailyChallengeCreated` trigger

---

#### Scenario 3: Foreground Notification Display
**Goal**: Verify SnackBar shown when app is in foreground

**Steps**:
1. Open app on test device
2. Keep app in foreground
3. Trigger notification (manual or scheduled)
4. Observe SnackBar appearance

**Expected Results**:
- ✅ SnackBar displays at bottom of screen
- ✅ SnackBar shows notification title and body
- ✅ "View" action button visible
- ✅ Tapping "View" navigates to `/daily-challenge`

**Code Reference**: `lib/main.dart:319-338` (FirebaseMessaging.onMessage listener)

---

#### Scenario 4: Background Notification Navigation
**Goal**: Verify tapping notification opens daily challenge screen

**Steps**:
1. Close app or send to background
2. Trigger notification
3. Tap notification from system tray/notification center
4. Observe app behavior

**Expected Results**:
- ✅ App opens (or comes to foreground)
- ✅ Navigates to `/daily-challenge` route
- ✅ DailyChallengeScreen displays with today's challenge

**Code Reference**: `lib/main.dart:300` (`_handleNotificationMessage` method)

---

#### Scenario 5: Notification Payload Validation
**Goal**: Verify notification contains correct data

**Steps**:
1. Check notification payload in Cloud Functions logs or device logs
2. Verify payload structure:
   ```json
   {
     "notification": {
       "title": "Daily Challenge Available!",
       "body": "A new daily challenge is ready. Compete for the top spot!"
     },
     "data": {
       "type": "daily_challenge",
       "dateId": "2026-01-30"
     }
   }
   ```

**Expected Results**:
- ✅ `data.type` equals `"daily_challenge"`
- ✅ `data.dateId` contains valid ISO date
- ✅ Title and body are user-friendly

**Code Reference**: `functions/src/services/notificationService.ts`

---

#### Scenario 6: Multiple Users Notification Broadcast
**Goal**: Verify all registered users receive notification

**Steps**:
1. Register multiple test accounts with FCM tokens
2. Trigger challenge generation
3. Check each device for notification

**Expected Results**:
- ✅ All registered users receive notification
- ✅ Cloud Functions logs show successful sends
- ✅ Any failed sends logged with error details

---

#### Scenario 7: Duplicate Prevention
**Goal**: Verify notification sent only once per challenge

**Steps**:
1. Create challenge (notification sent, `notificationSent: false` → `true`)
2. Attempt to trigger notification again for same challenge
3. Check Cloud Functions logs

**Expected Results**:
- ✅ Notification sent only on first trigger
- ✅ Subsequent attempts skip notification (check `notificationSent` flag)
- ✅ No duplicate notifications received

**Code Reference**: `functions/src/functions/dailyChallenge.ts:139` (check `notificationSent` flag)

---

### Testing Tools

#### Firebase Console
- **Firestore**: View challenge documents and completion entries
- **Cloud Functions**: Check logs, metrics, and execution history
- **Cloud Messaging**: Test notification sending to specific tokens

#### Firebase CLI Commands
```bash
# Deploy functions
firebase deploy --only functions

# View logs (live tail)
firebase functions:log --only onDailyChallengeCreated

# Manually trigger scheduled function (requires Pub/Sub)
gcloud pubsub topics publish firebase-schedule-scheduledDailyChallengeGenerator --message="{}"

# Get Firestore document
firebase firestore:get dailyChallenges/$(date +%Y-%m-%d)
```

#### Manual Notification Trigger
```bash
# Using manualSendNotification function
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/manualSendNotification \
  -H "Content-Type: application/json" \
  -d '{"challengeId": "2026-01-30"}'
```

#### Device Testing
- **Android**: Use `adb logcat` to view system logs and FCM messages
  ```bash
  adb logcat | grep -i "firebase\|fcm\|notification"
  ```
- **iOS**: Use Xcode Console to view device logs

---

### Common Issues & Troubleshooting

#### Issue: Notification not received
**Possible Causes**:
1. FCM token not registered or expired
2. Device permissions not granted
3. Cloud Function failed or timed out
4. Network connectivity issues

**Debug Steps**:
1. Check Cloud Functions logs for errors
2. Verify FCM token stored in Firestore/device
3. Test with Firebase Console → Cloud Messaging → Send test message
4. Check device notification permissions

#### Issue: Navigation not working
**Possible Causes**:
1. Route not defined in MaterialApp
2. `data.type` field missing or incorrect
3. Navigation handler not registered

**Debug Steps**:
1. Verify route defined at `lib/main.dart` (MaterialApp routes)
2. Check notification payload has `data.type: "daily_challenge"`
3. Add debug logs in `_handleNotificationMessage` method
4. Test navigation manually: `Navigator.pushNamed(context, '/daily-challenge')`

#### Issue: Foreground SnackBar not showing
**Possible Causes**:
1. `FirebaseMessaging.onMessage` listener not registered
2. SnackBar context not available
3. Background/foreground state detection incorrect

**Debug Steps**:
1. Verify listener at `lib/main.dart:319`
2. Add debug logs to confirm listener called
3. Check ScaffoldMessenger context availability

---

### Test Checklist

Use this checklist to track testing progress:

- [ ] Scheduled challenge generation works (11:00 UTC)
- [ ] Manual challenge generation works (`manualGenerateChallenge`)
- [ ] `onDailyChallengeCreated` trigger fires on document creation
- [ ] Notification sent to all registered users
- [ ] Foreground notification shows SnackBar with "View" action
- [ ] Background notification tap opens app at `/daily-challenge`
- [ ] Notification payload contains correct `type` and `dateId`
- [ ] Duplicate notifications prevented (`notificationSent` flag)
- [ ] Cloud Functions logs show no errors
- [ ] All test devices receive notifications within 30 seconds
- [ ] Android notification display correct
- [ ] iOS notification display correct (if applicable)

---

### Sign-Off

**Tester Name**: _________________
**Date**: _________________
**Test Environment**: Production / Staging / Local
**Result**: Pass / Fail
**Notes**: _________________________________________________

---

## Next Steps

After completing this testing:
1. Mark Task 18 as completed in `tasks.md`
2. Document any issues found in GitHub Issues
3. Proceed to Task 22 (Cloud Functions deployment to production)
4. Complete Task 23 (Final verification and handoff)
