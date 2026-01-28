# Implementation Plan: All Phases

## Status: Ready to implement Phases 2-5

### ✅ Phase 1: COMPLETE
- Firestore database created
- Test data populated (10 leaderboard users, daily challenge with completions)

### 🚀 Phase 2: Server-Side Daily Challenge Generation
**Goal**: Automated challenge creation at midnight UTC

**Implementation**:
1. Initialize Cloud Functions project
2. Create scheduled function (Cloud Scheduler cron: `0 0 * * *`)
3. Implement level generator algorithm
4. Store challenge in Firestore
5. Test locally, deploy to Firebase

**Files to create**:
- `functions/package.json`
- `functions/src/index.ts`
- `functions/src/dailyChallengeGenerator.ts`
- `functions/src/levelGenerator.ts`

### 🔔 Phase 3: Push Notifications
**Goal**: Notify users when new challenge available

**Implementation**:
1. Create Cloud Function triggered on daily challenge creation
2. Query users collection for FCM tokens
3. Send batch notifications via FCM
4. Add notification preferences to user model

**Files to create**:
- `functions/src/sendDailyChallengeNotification.ts`
- Update: `lib/domain/models/user.dart` (add notificationPreferences)

### ⚡ Phase 4: Leaderboard Optimization
**Goal**: Fast queries, real-time updates

**Implementation**:
1. Create Firestore composite indexes
2. Implement pagination in repository
3. Add caching layer for top 100
4. Optimize rank calculation

**Files to update**:
- `firestore.indexes.json`
- `lib/data/firebase/firebase_leaderboard_repository.dart`
- `lib/presentation/providers/leaderboard_provider.dart`

### 🧪 Phase 5: E2E Tests
**Goal**: Comprehensive test coverage

**Implementation**:
1. Setup Flutter integration test infrastructure
2. Write E2E tests for daily challenge flow
3. Write E2E tests for leaderboard
4. Write E2E tests for notifications
5. Add to CI/CD pipeline

**Files to create**:
- `test/e2e/daily_challenge_test.dart`
- `test/e2e/leaderboard_test.dart`
- `test/e2e/notification_test.dart`
- `.github/workflows/e2e_tests.yml`

## Execution Order
1. Phase 2 (Cloud Functions) - Core automation
2. Phase 3 (Notifications) - User engagement
3. Phase 4 (Optimization) - Performance
4. Phase 5 (E2E Tests) - Quality assurance

## Estimated Timeline
- Phase 2: 1-2 hours
- Phase 3: 1 hour
- Phase 4: 30 minutes
- Phase 5: 2-3 hours
- **Total**: 5-7 hours
