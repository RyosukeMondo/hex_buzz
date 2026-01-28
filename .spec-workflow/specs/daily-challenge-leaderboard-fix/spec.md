# Daily Challenge & Leaderboard Enhancement

**Status:** draft
**Priority:** high
**Created:** 2026-01-27
**Epic:** Game Features Enhancement

## Problem Statement

Current issues:
1. Daily challenge screen shows infinite loading - no challenge data exists in Firestore
2. Leaderboard shows infinite loading - no leaderboard data exists in Firestore
3. No server-side daily challenge generation (challenges must be manually created)
4. No push notifications for new daily challenges
5. Missing E2E tests for these features

## Goals

1. **Immediate Fix**: Populate Firestore with test data to unblock UI
2. **Server-Side Generation**: Implement automated daily challenge creation via Cloud Functions
3. **Push Notifications**: Send FCM notifications when new challenges are available
4. **Effective Leaderboard**: Optimize leaderboard queries and display
5. **Test Coverage**: Add comprehensive E2E tests after UT/IT are complete

## Success Criteria

- [ ] Daily challenge screen shows content (not infinite loading)
- [ ] Leaderboard screen shows content (not infinite loading)
- [ ] New daily challenges generated automatically at midnight UTC
- [ ] Push notifications sent to users when new challenge is available
- [ ] Leaderboard updates in real-time
- [ ] Full E2E test coverage (daily challenge flow, leaderboard updates, notifications)
- [ ] All existing unit tests and integration tests pass

## Implementation Phases

### Phase 1: Immediate Fix (Data Population)
**Goal**: Unblock UI by populating Firestore with test data

Tasks:
1. Create script to populate daily challenges for current date
2. Create script to populate leaderboard with test users
3. Verify UI displays content correctly
4. Document manual data population process

**Files**:
- `scripts/populate_daily_challenge.dart`
- `scripts/populate_leaderboard.dart`

### Phase 2: Server-Side Daily Challenge Generation
**Goal**: Automate daily challenge creation

Tasks:
1. Setup Firebase Cloud Functions project
2. Create scheduled function to run daily at midnight UTC
3. Implement level generation algorithm for daily challenges
4. Store generated challenge in Firestore
5. Add error handling and logging
6. Test function locally
7. Deploy to Firebase

**Files**:
- `functions/src/daily_challenge_generator.ts`
- `functions/src/index.ts`
- `functions/package.json`

### Phase 3: Push Notifications
**Goal**: Notify users of new daily challenges

Tasks:
1. Update FCM notification service to handle daily challenge notifications
2. Add Cloud Function trigger on new daily challenge creation
3. Query active users and send FCM notifications
4. Add notification preferences (allow users to opt-out)
5. Test notification delivery

**Files**:
- `functions/src/send_daily_challenge_notification.ts`
- `lib/domain/services/notification_service.dart` (update)

### Phase 4: Leaderboard Optimization
**Goal**: Improve leaderboard performance and display

Tasks:
1. Add Firestore composite indexes for leaderboard queries
2. Implement pagination for large leaderboards
3. Add caching layer for top 100 players
4. Add real-time updates using Firestore streams
5. Optimize user rank calculation

**Files**:
- `firestore.indexes.json`
- `lib/data/firebase/firebase_leaderboard_repository.dart` (optimize)
- `lib/presentation/providers/leaderboard_provider.dart` (update)

### Phase 5: E2E Tests
**Goal**: Comprehensive test coverage

Tasks:
1. Wait for all unit tests (UT) and integration tests (IT) to pass
2. Setup E2E test infrastructure (Flutter integration tests)
3. Write E2E test: Complete daily challenge flow
4. Write E2E test: View leaderboard and verify rankings
5. Write E2E test: Receive push notification for new challenge
6. Write E2E test: Submit score and verify leaderboard update
7. Run E2E tests in CI/CD pipeline

**Files**:
- `test/e2e/daily_challenge_flow_test.dart`
- `test/e2e/leaderboard_test.dart`
- `test/e2e/push_notification_test.dart`
- `.github/workflows/e2e_tests.yml`

## Technical Specifications

### Daily Challenge Document Structure (Firestore)
```json
{
  "dailyChallenges/{YYYY-MM-DD}": {
    "id": "2026-01-27",
    "createdAt": "2026-01-27T00:00:00Z",
    "level": {
      "id": "daily-2026-01-27",
      "gridSize": 8,
      "difficulty": "medium",
      "cells": [...],
      "startPosition": {"q": 0, "r": 0},
      "endPosition": {"q": 7, "r": 7}
    },
    "completionCount": 0,
    "notificationSent": false
  },
  "dailyChallenges/{YYYY-MM-DD}/completions/{userId}": {
    "userId": "abc123",
    "stars": 3,
    "completionTimeMs": 45000,
    "completedAt": "2026-01-27T10:30:00Z"
  }
}
```

### Leaderboard Document Structure (Firestore)
```json
{
  "leaderboard/{userId}": {
    "userId": "abc123",
    "username": "Player1",
    "avatarUrl": "https://...",
    "totalStars": 150,
    "updatedAt": "2026-01-27T10:30:00Z",
    "lastLevel": "level-10"
  }
}
```

### Cloud Function Schedule
- **Trigger**: Cloud Scheduler (cron: `0 0 * * *` - daily at midnight UTC)
- **Function**: `generateDailyChallenge`
- **Runtime**: Node.js 20
- **Timeout**: 60 seconds
- **Memory**: 256MB

### Push Notification Format
```json
{
  "notification": {
    "title": "🐝 New Daily Challenge!",
    "body": "A new challenge is ready. Can you beat today's puzzle?"
  },
  "data": {
    "type": "daily_challenge",
    "challengeId": "2026-01-27",
    "route": "/daily-challenge"
  }
}
```

## Dependencies

- Firebase Cloud Functions
- Firebase Cloud Scheduler
- Firebase Cloud Messaging (FCM)
- Firestore composite indexes

## Risks & Mitigations

**Risk**: Cloud Functions cold start delays challenge generation
**Mitigation**: Use Cloud Scheduler with 15-minute window, retry on failure

**Risk**: Push notifications fail for some users
**Mitigation**: Log failures, implement retry logic, track delivery metrics

**Risk**: Leaderboard queries slow with many users
**Mitigation**: Implement caching, composite indexes, pagination

## Testing Strategy

1. **Unit Tests**: Test level generation logic, notification formatting
2. **Integration Tests**: Test Firestore writes, FCM delivery
3. **E2E Tests**: Test complete user flows (Phase 5)
4. **Load Tests**: Test leaderboard with 10k+ users

## Rollout Plan

1. Deploy Phase 1 immediately (test data population)
2. Deploy Phase 2-3 together (challenge generation + notifications)
3. Deploy Phase 4 after monitoring Phase 2-3 performance
4. Deploy Phase 5 E2E tests in CI/CD

## Monitoring

- Track daily challenge generation success rate
- Track push notification delivery rate
- Track leaderboard query latency (P50, P95, P99)
- Track daily challenge completion rate
- Alert if challenge generation fails 2 days in a row

## Documentation

- Update README with daily challenge feature
- Document Cloud Functions deployment process
- Document Firestore schema for challenges and leaderboard
- Create troubleshooting guide for common issues
