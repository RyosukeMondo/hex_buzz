# Daily Challenge Refinement - Design Document

## 1. System Architecture

### 1.1 High-Level Overview
```
┌─────────────────────────────────────────────────────────────┐
│                     HexBuzz Client (Flutter)                 │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Daily     │  │   Social    │  │   Notif     │        │
│  │  Challenge  │  │    Share    │  │  Handler    │        │
│  │   Screen    │  │   Service   │  │             │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                 │                 │               │
│         │                 │                 │               │
│  ┌──────▼─────────────────▼─────────────────▼──────┐       │
│  │      DailyChallengeProvider (State Manager)      │       │
│  └──────┬───────────────────────────────────────────┘       │
│         │                                                    │
│  ┌──────▼──────────────────────────────┐                   │
│  │  DailyChallengeRepository (Domain)  │                   │
│  └──────┬──────────────────────────────┘                   │
└─────────┼──────────────────────────────────────────────────┘
          │
          │ Firestore / FCM
          │
┌─────────▼──────────────────────────────────────────────────┐
│                    Firebase Backend                         │
│                                                              │
│  ┌─────────────────┐  ┌──────────────────────────────┐    │
│  │   Firestore     │  │    Cloud Functions            │    │
│  │                 │  │                               │    │
│  │ dailyChallenges │  │ - validateCompletion          │    │
│  │  └─ entries     │  │ - onDailyChallengeCreated     │    │
│  │                 │  │ - sendNotifications           │    │
│  └─────────────────┘  └──────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────┐       │
│  │         Security Rules                           │       │
│  │  - One completion per user per day               │       │
│  │  - No updates/deletes of completions             │       │
│  └─────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Component Interaction Flow

#### Flow 1: Starting Daily Challenge
```
User → DailyChallengeScreen → DailyChallengeProvider
  ↓
  loadChallenge()
  ↓
DailyChallengeRepository.getCompletion(userId, dateId)
  ↓
Firestore query: dailyChallenges/{dateId}/entries/{userId}
  ↓
If exists: State → alreadyCompleted
If not: State → notStarted → User taps "Start" → State → playing
```

#### Flow 2: Completing Challenge
```
User completes puzzle → DailyChallengeProvider.complete(stars)
  ↓
Call: validateDailyChallengeCompletion Cloud Function
  ↓
Function validates: auth, no duplicate, valid data
  ↓
Function writes to Firestore: dailyChallenges/{dateId}/entries/{userId}
  ↓
Function calculates rank by querying leaderboard
  ↓
Returns: { success, rank, totalPlayers }
  ↓
State → completed → Shows completion dialog
```

#### Flow 3: Daily Challenge Creation & Notification
```
Scheduled Cloud Function runs (0 0 * * * - midnight UTC)
  ↓
generateDailyChallenge() creates dailyChallenges/{dateId} document
  ↓
Firestore trigger: onDailyChallengeCreated
  ↓
sendDailyChallengeNotification() Cloud Function
  ↓
Query all users with FCM tokens
  ↓
Send FCM notification with data: { type: 'daily_challenge', dateId }
  ↓
User receives notification
  ↓
User taps notification
  ↓
App navigation handler: routes to /daily-challenge
```

## 2. Data Models

### 2.1 DailyChallengeState (Freezed Sealed Union)
```dart
@freezed
sealed class DailyChallengeState with _$DailyChallengeState {
  // Initial state when loading challenge
  const factory DailyChallengeState.loading() = DailyChallengeStateLoading;

  // Challenge loaded, user hasn't started yet
  const factory DailyChallengeState.notStarted(
    DailyChallenge challenge,
  ) = DailyChallengeStateNotStarted;

  // User is actively playing
  const factory DailyChallengeState.playing(
    DailyChallenge challenge,
    DateTime startTime,
    List<HexCoordinate> currentPath,
  ) = DailyChallengeStatePlaying;

  // User suspended (paused) the challenge
  const factory DailyChallengeState.suspended(
    DailyChallenge challenge,
    DateTime startTime,
    DateTime suspendedTime,
    List<HexCoordinate> currentPath,
  ) = DailyChallengeStateSuspended;

  // User completed challenge today (first view after completion)
  const factory DailyChallengeState.completed(
    DailyChallengeCompletion completion,
  ) = DailyChallengeStateCompleted;

  // User attempted to start already-completed challenge
  const factory DailyChallengeState.alreadyCompleted(
    DailyChallengeCompletion completion,
  ) = DailyChallengeStateAlreadyCompleted;

  // Error occurred
  const factory DailyChallengeState.error(
    String message,
  ) = DailyChallengeStateError;
}
```

### 2.2 Firestore Schema

#### Collection: `dailyChallenges/{dateId}`
```typescript
interface DailyChallenge {
  id: string;                    // YYYY-MM-DD
  createdAt: string;             // ISO 8601 timestamp
  level: {
    id: string;
    gridSize: number;
    difficulty: 'easy' | 'medium' | 'hard';
    cells: HexCell[];
    walls: HexEdge[];
    startPosition: HexCoordinate;
    endPosition: HexCoordinate;
    checkpoints?: HexCoordinate[];
  };
  completionCount: number;       // Total completions
  notificationSent: boolean;     // Has notification been sent
}
```

#### Sub-collection: `dailyChallenges/{dateId}/entries/{userId}`
```typescript
interface DailyChallengeEntry {
  userId: string;                // User ID (document ID)
  username: string;              // Display name
  stars: number;                 // 0-3
  completionTimeMs: number;      // Milliseconds
  completedAt: string;           // ISO 8601 timestamp
}
```

### 2.3 Domain Models

```dart
@freezed
class DailyChallenge with _$DailyChallenge {
  const factory DailyChallenge({
    required String id,
    required DateTime createdAt,
    required Level level,
    required int completionCount,
    required bool notificationSent,
  }) = _DailyChallenge;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) =>
      _$DailyChallengeFromJson(json);
}

@freezed
class DailyChallengeCompletion with _$DailyChallengeCompletion {
  const factory DailyChallengeCompletion({
    required String userId,
    required String username,
    required String dateId,
    required int stars,
    required int completionTimeMs,
    required DateTime completedAt,
    required int rank,              // Calculated by backend
    required int totalPlayers,      // Calculated by backend
  }) = _DailyChallengeCompletion;

  factory DailyChallengeCompletion.fromJson(Map<String, dynamic> json) =>
      _$DailyChallengeCompletionFromJson(json);
}
```

## 3. API Design

### 3.1 Cloud Functions

#### validateDailyChallengeCompletion (Callable)
```typescript
/**
 * Validates and saves daily challenge completion
 * Prevents duplicate submissions and calculates rank
 */
interface ValidateCompletionRequest {
  dateId: string;              // YYYY-MM-DD
  stars: number;               // 0-3
  completionTimeMs: number;    // Must be >= 1000
}

interface ValidateCompletionResponse {
  success: boolean;
  rank: number;                // 1-based rank
  totalPlayers: number;        // Total completions
}

// Security: Requires authentication
// Validation: Checks for existing completion, validates data
// Error: Throws HttpsError for failures
```

#### onDailyChallengeCreated (Firestore Trigger)
```typescript
/**
 * Triggered when new daily challenge document created
 * Sends push notifications to all users
 */
// Trigger: onCreate dailyChallenges/{dateId}
// Action: Call sendDailyChallengeNotification(dateId)
```

#### sendDailyChallengeNotification (Callable/Internal)
```typescript
/**
 * Sends FCM notifications to all users with tokens
 */
interface NotificationMessage {
  notification: {
    title: "🐝 New Daily Challenge!";
    body: "A new puzzle is ready. Can you beat today's challenge?";
  };
  data: {
    type: "daily_challenge";
    dateId: string;            // YYYY-MM-DD
    route: "/daily-challenge";
  };
}
```

### 3.2 Repository Interface

```dart
abstract class DailyChallengeRepository {
  /// Get today's daily challenge
  Future<DailyChallenge> getTodayChallenge();

  /// Check if user has completed a specific challenge
  Future<DailyChallengeCompletion?> getCompletion({
    required String userId,
    required String dateId,
  });

  /// Submit completion (calls Cloud Function for validation)
  Future<DailyChallengeCompletion> submitCompletion({
    required String userId,
    required String username,
    required String dateId,
    required int stars,
    required int completionTimeMs,
  });

  /// Stream leaderboard for a specific date
  Stream<List<DailyChallengeEntry>> streamLeaderboard({
    required String dateId,
    int limit = 50,
  });
}
```

## 4. UI/UX Design

### 4.1 Screen States

#### State: Not Started
```
┌─────────────────────────────────────┐
│  🐝 Today's Daily Challenge         │
│                                     │
│  ╔═══════════════════════════╗     │
│  ║   [Preview of hex grid]   ║     │
│  ║                           ║     │
│  ║      8x8 Grid             ║     │
│  ║      Medium Difficulty    ║     │
│  ╚═══════════════════════════╝     │
│                                     │
│  ┌──────────────────────────┐      │
│  │    START CHALLENGE       │      │
│  └──────────────────────────┘      │
│                                     │
│  View Daily Leaderboard             │
└─────────────────────────────────────┘
```

#### State: Playing
```
┌─────────────────────────────────────┐
│  ⏱️  2:15  [Suspend]                 │
│                                     │
│  ╔═══════════════════════════╗     │
│  ║                           ║     │
│  ║   [Active hex grid game]  ║     │
│  ║   [User can make moves]   ║     │
│  ║                           ║     │
│  ╚═══════════════════════════╝     │
│                                     │
│  ⭐⭐⭐  Path: 45/64 cells          │
│                                     │
│  [Undo]         [Reset Path]       │
└─────────────────────────────────────┘
```

#### State: Suspended
```
┌─────────────────────────────────────┐
│        Challenge Paused ⏸️           │
│                                     │
│    Timer is still running! ⏱️       │
│         Elapsed: 2:45               │
│                                     │
│  ╔═══════════════════════════╗     │
│  ║   [Frozen hex grid view]  ║     │
│  ║   [Shows current state]   ║     │
│  ╚═══════════════════════════╝     │
│                                     │
│  ┌──────────────────────────┐      │
│  │    RESUME CHALLENGE      │      │
│  └──────────────────────────┘      │
│                                     │
│  [Back to Menu]                     │
└─────────────────────────────────────┘
```

#### State: Completed / Already Completed
```
┌─────────────────────────────────────┐
│    🎉 Challenge Complete! 🎉        │
│                                     │
│        ⭐⭐⭐  3 Stars               │
│        ⏱️  2:34  Time               │
│        🏆  Rank #12                 │
│                                     │
│  Share your result:                 │
│  [🐦 Twitter] [🟢 Misskey] [📘 FB] │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   📊 Daily Leaderboard      │   │
│  │                             │   │
│  │  🥇 1. FastPlayer  ⭐⭐⭐ 1:23 │   │
│  │  🥈 2. QuickBee    ⭐⭐⭐ 1:45 │   │
│  │  🥉 3. SpeedySolv  ⭐⭐⭐ 2:01 │   │
│  │  ...                        │   │
│  │ ▶12. You          ⭐⭐⭐ 2:34◀│   │
│  │  ...                        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Come back tomorrow for a new       │
│  challenge!                         │
│                                     │
│  [Back to Menu]                     │
└─────────────────────────────────────┘
```

### 4.2 Share Dialog Design

```
┌─────────────────────────────────────┐
│  Share to Twitter                   │
│  ─────────────                      │
│                                     │
│  Preview:                           │
│  ┌─────────────────────────────┐   │
│  │ 🐝 I completed today's      │   │
│  │ HexBuzz challenge in 2m 34s!│   │
│  │ ⭐⭐⭐                         │   │
│  │                             │   │
│  │ Can you beat my time?       │   │
│  │                             │   │
│  │ https://hexbuzz.app/        │   │
│  │ daily/2026-01-30            │   │
│  │                             │   │
│  │ #HexBuzz #DailyChallenge    │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Cancel]        [Share Tweet]      │
└─────────────────────────────────────┘
```

### 4.3 Misskey Instance Picker

```
┌─────────────────────────────────────┐
│  Select Misskey Instance            │
│  ─────────────────────              │
│                                     │
│  ◉ misskey.io                       │
│  ○ misskey.dev                      │
│  ○ fedibird.com                     │
│  ○ mstdn.jp                         │
│  ○ Custom:                          │
│     ┌────────────────────────┐     │
│     │ Enter instance URL...  │     │
│     └────────────────────────┘     │
│                                     │
│  [Cancel]               [OK]        │
└─────────────────────────────────────┘
```

## 5. Security Design

### 5.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Daily challenges
    match /dailyChallenges/{dateId} {
      // Anyone can read challenges
      allow read: if true;

      // Only Cloud Functions can write challenges
      allow write: if false;

      // Completions/entries
      match /entries/{userId} {
        // Anyone can read leaderboard
        allow read: if true;

        // Can create completion if:
        // 1. User is authenticated
        // 2. Document ID matches authenticated user ID
        // 3. No existing document for this user+date
        allow create: if request.auth != null
          && request.auth.uid == userId
          && !exists(/databases/$(database)/documents/
                     dailyChallenges/$(dateId)/entries/$(userId));

        // No updates or deletes - completions are immutable
        allow update, delete: if false;
      }
    }
  }
}
```

### 5.2 Cloud Function Validation

```typescript
// Input validation
if (!auth?.uid) throw new HttpsError('unauthenticated', 'Must be signed in');
if (stars < 0 || stars > 3) throw new HttpsError('invalid-argument', 'Invalid stars');
if (completionTimeMs < 1000) throw new HttpsError('invalid-argument', 'Time too fast');

// Duplicate check
const existing = await db
  .collection('dailyChallenges')
  .doc(dateId)
  .collection('entries')
  .doc(userId)
  .get();

if (existing.exists) {
  throw new HttpsError('already-exists', 'Already completed today');
}

// Atomic write with validation
await db.runTransaction(async (transaction) => {
  // Write completion
  transaction.set(entryRef, completionData);

  // Increment completion count
  transaction.update(challengeRef, {
    completionCount: admin.firestore.FieldValue.increment(1),
  });
});
```

## 6. Performance Optimization

### 6.1 Query Optimization
- Leaderboard limited to 50 entries (pagination future enhancement)
- Composite index on entries: (stars DESC, completionTimeMs ASC)
- Streaming queries for real-time updates

### 6.2 Caching Strategy
- Daily challenge cached in provider state
- Completion status cached after first check
- Leaderboard uses Firestore's built-in caching

### 6.3 Lazy Loading
- Share dialogs loaded only when opened
- Leaderboard widget loads only when completion dialog shown

## 7. Error Handling

### 7.1 Error States
- Network error: Show retry button
- Duplicate completion: Show already completed state
- Invalid data: Log error, show generic message
- Cloud Function error: Parse and display user-friendly message

### 7.2 Logging Strategy
```dart
// State transitions
DiagnosticLogger.logEvent('daily_challenge_started', data: {
  'dateId': dateId,
  'userId': userId,
});

// Errors
DiagnosticLogger.logError('daily_challenge_submit_failed', error, data: {
  'dateId': dateId,
  'userId': userId,
  'stars': stars,
});

// User actions
DiagnosticLogger.logEvent('daily_challenge_shared', data: {
  'platform': 'twitter',
  'dateId': dateId,
});
```

## 8. Testing Strategy

### 8.1 Unit Tests
- All provider state transitions
- Cloud Function validation logic
- Share URL generation
- Time formatting utilities

### 8.2 Widget Tests
- All screen states render correctly
- Share buttons appear and trigger correct actions
- Leaderboard displays and highlights current user
- Completion dialog shows correct data

### 8.3 Integration Tests
- Full user flow: start → play → suspend → resume → complete
- Duplicate submission prevention
- Notification navigation
- Real-time leaderboard updates

### 8.4 Manual Tests
- FCM notification delivery
- Social sharing on real devices
- Cross-platform consistency
- Edge cases (network interruption, app backgrounding)

## 9. Migration Strategy

### 9.1 Data Migration
- No data migration needed (new feature)
- Existing users see daily challenge with clean slate

### 9.2 Code Migration
- Global leaderboard code removal
- Update navigation structure
- Deploy Cloud Functions first, then client app

### 9.3 Rollout Plan
1. Deploy Firestore security rules (non-breaking)
2. Deploy Cloud Functions (validateCompletion, notifications)
3. Deploy Flutter app update
4. Monitor for 24 hours
5. Announce feature to users

## 10. Monitoring & Analytics

### 10.1 Key Metrics
- Daily challenge starts per day
- Completion rate (started/completed)
- Average completion time
- Share button clicks by platform
- Notification delivery rate
- Notification tap-through rate

### 10.2 Alerts
- Duplicate completion detected (should be zero)
- Cloud Function errors > 1%
- Notification delivery < 90%
- Average completion time anomaly

### 10.3 Dashboards
- Daily challenge participation trends
- Leaderboard distribution (stars, time)
- Social share conversion rate
- User retention impact
