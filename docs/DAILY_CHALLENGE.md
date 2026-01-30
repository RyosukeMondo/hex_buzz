# Daily Challenge Feature

## Overview

The Daily Challenge feature provides players with a new hexagonal puzzle every day at midnight UTC. Players can attempt each challenge **once per day**, with results tracked on a daily leaderboard. The feature includes push notifications, social sharing, and fair play enforcement through backend validation.

## Rules

### One Attempt Per Day
- Each user can complete the daily challenge **only once**
- After completion, the challenge cannot be retried until the next day
- Attempting to start an already-completed challenge shows the "Already Completed" state

### Timer Cannot Restart
- The challenge timer starts when you begin playing
- Suspending (pausing) the challenge keeps the timer running
- Resuming the challenge continues from the original start time
- The timer **cannot be reset** - your first attempt time is final

### First Completion Counts
- Only your first successful completion is recorded
- Your score (stars and time) determines your rank on the daily leaderboard
- Rank is calculated in real-time when you complete the challenge

## Features

### Push Notifications
- Daily notifications sent at midnight UTC when new challenges are available
- Tap the notification to navigate directly to the daily challenge screen
- Foreground notifications show a SnackBar with "View" action

### Social Sharing
After completing a challenge, share your results on:
- **Twitter**: Tweet your time, stars, and link to the game
- **Misskey**: Post to your favorite Misskey instance (common instances + custom)
- **Facebook**: Share your achievement with friends

Share messages include:
```
🐝 I completed today's HexBuzz daily challenge in 42.3s with ⭐⭐⭐! Can you beat my time? #HexBuzz
```

### Daily Leaderboard
- View rankings for today's challenge after completion
- Top 3 players highlighted with medals (🥇🥈🥉)
- Your position highlighted in the list
- Sorted by stars (descending), then by completion time (ascending)
- Real-time updates as more players complete the challenge

## User Flow

### 1. Receive Notification
At midnight UTC each day, you receive a push notification:
```
🐝 New Daily Challenge Available!
Today's puzzle is waiting for you.
```

### 2. Start Challenge
Tap the notification or navigate to the Daily Challenge screen:
- See "Today's Challenge" with "Start Challenge" button
- Tap "Start Challenge" to begin
- Timer starts immediately

### 3. Play
- Draw a path through all hexagonal cells
- Earn 1-3 stars based on performance
- Can suspend (pause) and resume anytime
- Timer continues running during suspension

### 4. Complete
- Finish the puzzle to submit your completion
- Backend validates your attempt (prevents cheating)
- Receive your rank among all players
- View completion dialog with:
  - Your stars (⭐⭐⭐)
  - Your completion time
  - Your rank (#1 of 127 players)
  - Share buttons for social media
  - Daily leaderboard

### 5. Share (Optional)
Tap any social share button to:
- Generate a formatted message with your stats
- Open the platform's sharing interface
- Post your achievement

## Technical Implementation

### Architecture

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

### State Machine

The daily challenge uses a sealed union state machine with 7 states:

1. **Loading**: Initial state while fetching challenge data
2. **NotStarted**: Challenge loaded, ready to start (shows "Start Challenge" button)
3. **Playing**: User actively playing (timer running, can make moves)
4. **Suspended**: Challenge paused (timer still running, no moves allowed)
5. **Completed**: Just completed (shows completion dialog, first view after completion)
6. **AlreadyCompleted**: User attempted to retry (shows "You've completed this challenge")
7. **Error**: Something went wrong (shows error message)

State transitions:
```
Loading → NotStarted → Playing ⇄ Suspended → Completed
   ↓           ↓
  Error   AlreadyCompleted
```

### Firestore Structure

#### Collection: `dailyChallenges/{dateId}`
```typescript
{
  id: "2026-01-30",           // YYYY-MM-DD format
  date: "2026-01-30T00:00:00Z",
  level: {                     // The puzzle data
    id: "daily-2026-01-30",
    size: 4,
    cells: {...},
    walls: {...},
    checkpointCount: 2
  },
  completionCount: 127,        // Total completions
  createdAt: "2026-01-30T00:00:00Z"
}
```

#### Subcollection: `dailyChallenges/{dateId}/entries/{userId}`
```typescript
{
  userId: "user123",
  dateId: "2026-01-30",
  stars: 3,                    // 1-3 stars
  completionTimeMs: 42300,     // Time in milliseconds
  completedAt: "2026-01-30T08:15:00Z",
  rank: 15                     // Position on leaderboard
}
```

### Security Rules

Firestore security rules enforce one-attempt-per-day:

```javascript
// Only allow create if no existing completion for this user today
allow create: if
  request.auth != null &&
  request.auth.uid == request.resource.data.userId &&
  !exists(/databases/$(database)/documents/dailyChallenges/$(dateId)/entries/$(request.auth.uid)) &&
  request.resource.data.stars >= 0 && request.resource.data.stars <= 3 &&
  request.resource.data.completionTimeMs > 0;

// No updates or deletes allowed
allow update, delete: if false;
```

### Cloud Functions

#### validateDailyChallengeCompletion
Callable function that validates and records completions:

```typescript
export const validateDailyChallengeCompletion = functions.https.onCall(
  async (data, context) => {
    // 1. Authenticate user
    // 2. Check for duplicate completions
    // 3. Validate stars (1-3) and time (> 0)
    // 4. Write completion to Firestore
    // 5. Calculate rank by querying leaderboard
    // 6. Return rank and total players
  }
);
```

#### onDailyChallengeCreated
Firestore trigger that sends notifications when new challenges are created:

```typescript
export const onDailyChallengeCreated = functions.firestore
  .document('dailyChallenges/{dateId}')
  .onCreate(async (snapshot, context) => {
    // 1. Query all users with FCM tokens
    // 2. Send push notification: "New Daily Challenge Available!"
    // 3. Include data: { type: 'daily_challenge', dateId }
  });
```

## Testing

### Unit Tests
- `test/presentation/providers/daily_challenge_provider_test.dart`: Provider state machine tests
- `functions/test/functions/dailyChallenge.test.ts`: Cloud Function validation tests

### Integration Tests
- `integration_test/daily_challenge_complete_flow_test.dart`: End-to-end user flow tests
  - Start → Suspend → Resume → Complete flow
  - One-attempt enforcement
  - Timer preservation across suspend/resume
  - Multiple users completing independently
  - Leaderboard ranking validation

### Manual Testing Checklist
1. **Notification Flow**
   - [ ] Create daily challenge using Cloud Function
   - [ ] Verify notification received on device
   - [ ] Tap notification and verify navigation to daily challenge screen
   - [ ] Test foreground notification shows SnackBar with "View" action

2. **One-Attempt Enforcement**
   - [ ] Complete challenge successfully
   - [ ] Close and reopen app
   - [ ] Verify "Already Completed" state shown
   - [ ] Verify no "Retry" or "Start Challenge" button

3. **Timer Preservation**
   - [ ] Start challenge
   - [ ] Note start time
   - [ ] Suspend challenge
   - [ ] Wait 30 seconds
   - [ ] Resume challenge
   - [ ] Verify timer shows total elapsed time (not reset)

4. **Social Sharing**
   - [ ] Complete challenge
   - [ ] Tap Twitter share button → verify Twitter opens with message
   - [ ] Tap Misskey share button → select instance → verify Misskey opens
   - [ ] Tap Facebook share button → verify Facebook opens

5. **Leaderboard**
   - [ ] Complete challenge with multiple test users
   - [ ] Verify leaderboard shows all users
   - [ ] Verify sorting by stars then time
   - [ ] Verify current user highlighted
   - [ ] Verify top 3 have medals

## Troubleshooting

### Notification not received
- Check FCM token is registered in Firestore (`users/{userId}/fcmToken`)
- Verify Cloud Function `onDailyChallengeCreated` executed successfully in Firebase Console
- Check device notification permissions are enabled
- Test with Firebase Cloud Messaging test message

### "Already Completed" shows but I haven't completed today
- Check device timezone - challenge completion is based on UTC date
- Verify `dailyChallenges/{dateId}/entries/{userId}` document exists for today
- If incorrect, delete the entry (requires admin/console access)

### Timer shows incorrect time
- This should not happen - timer cannot be reset
- If you see this, it's a bug - startTime should be preserved across suspend/resume
- Check `DailyChallengeStatePlaying.startTime` and `DailyChallengeStateSuspended.startTime` are equal

### Share buttons don't open social media
- Check `url_launcher` package installed: `flutter pub get`
- Verify platform-specific configuration:
  - iOS: LSApplicationQueriesSchemes in Info.plist
  - Android: queries in AndroidManifest.xml
- Test with `canLaunchUrl()` before calling `launchUrl()`

### Leaderboard not updating
- Leaderboard uses real-time Firestore stream
- Verify network connection
- Check Firestore security rules allow reads of `dailyChallenges/{dateId}/entries`
- Query may be limited to top 100 entries

## Future Enhancements

Potential improvements for the daily challenge feature:

- **Weekly/Monthly leaderboards**: Aggregate rankings over longer periods
- **Challenge difficulty tiers**: Easy, Medium, Hard daily challenges
- **Streak tracking**: Reward consecutive daily completions
- **Challenge history**: View past challenges and your completions
- **Friend challenges**: Compete directly with specific users
- **Achievements**: Badges for milestones (10-day streak, top 10 finish, etc.)
- **Replays**: Watch how top players solved the challenge
- **Custom challenges**: Create and share challenges with others
