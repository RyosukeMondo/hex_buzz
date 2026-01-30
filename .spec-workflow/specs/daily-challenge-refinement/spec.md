# Daily Challenge Refinement

**Status:** in-progress
**Priority:** high
**Created:** 2026-01-30

## Problem Statement

Current daily challenge has several usability issues:
1. Users can restart and retry multiple times, making leaderboard unfair
2. Global leaderboard is unnecessary (daily only is sufficient)
3. No notification system for new challenges
4. No social sharing after completion
5. No prevention of second attempts

## Goals

Create a fair, engaging daily challenge experience:
1. **One attempt per day** - First completion only, no retries
2. **Suspend/resume** - Can pause but timer keeps running
3. **Daily leaderboard only** - Remove global leaderboard
4. **Notification system** - Alert users of new challenges
5. **Social sharing** - Share results to Twitter, Misskey, Facebook
6. **Post-completion UX** - Show result, prevent retries

## Success Criteria

- [ ] Users can only complete daily challenge once per day
- [ ] Timer cannot be restarted (can suspend/resume)
- [ ] Only daily leaderboard visible (global removed)
- [ ] Notifications sent when new challenge available
- [ ] Tap notification goes directly to daily challenge
- [ ] After completion: share buttons with time/link
- [ ] After completion: cannot retry (show result only)

## Implementation Tasks

### Task 1: Enforce One-Attempt-Per-Day

**Files to modify:**
- `lib/presentation/providers/daily_challenge_provider.dart`
- `lib/presentation/screens/daily_challenge_screen.dart`
- `lib/data/firebase/firestore_daily_challenge_repository.dart`

**Implementation:**
```dart
class DailyChallengeProvider extends StateNotifier<DailyChallengeState> {
  Future<void> startChallenge() async {
    // Check if already completed today
    final today = DateTime.now().toUtc();
    final dateId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existingCompletion = await _repository.getCompletion(
      userId: _authProvider.currentUser!.id,
      dateId: dateId,
    );

    if (existingCompletion != null) {
      // Already completed - show result only
      state = DailyChallengeState.completed(existingCompletion);
      return;
    }

    // Start new attempt (only if not completed)
    state = DailyChallengeState.playing(
      challenge: challenge,
      startTime: DateTime.now(),
      suspendedTime: null,
    );
  }

  Future<void> suspend() async {
    if (state is! DailyChallengeStatePlaying) return;

    final playing = state as DailyChallengeStatePlaying;
    state = DailyChallengeState.suspended(
      challenge: playing.challenge,
      startTime: playing.startTime,
      suspendedTime: DateTime.now(),
      currentPath: playing.currentPath,
    );
  }

  Future<void> resume() async {
    if (state is! DailyChallengeStateSuspended) return;

    final suspended = state as DailyChallengeStateSuspended;
    state = DailyChallengeState.playing(
      challenge: suspended.challenge,
      startTime: suspended.startTime,
      currentPath: suspended.currentPath,
      // Timer keeps running - no restart
    );
  }

  Future<void> complete() async {
    final playing = state as DailyChallengeStatePlaying;
    final elapsedMs = DateTime.now().difference(playing.startTime).inMilliseconds;

    // Submit completion (first and only time)
    final result = await _repository.submitCompletion(
      userId: _authProvider.currentUser!.id,
      dateId: playing.challenge.dateId,
      stars: _calculateStars(elapsedMs),
      completionTimeMs: elapsedMs,
    );

    state = DailyChallengeState.completed(result);
  }
}
```

### Task 2: Remove Global Leaderboard

**Files to modify:**
- `lib/presentation/screens/leaderboard_screen.dart` → DELETE or repurpose
- `lib/presentation/providers/leaderboard_provider.dart` → DELETE or repurpose
- `lib/presentation/screens/front_screen.dart` - Remove navigation button

**Implementation:**
1. Remove global leaderboard button from main menu
2. Daily challenge screen shows only daily leaderboard
3. Delete unused global leaderboard code

### Task 3: Notification System

**Files to modify:**
- `lib/main.dart` - Already has notification navigation
- `functions/src/functions/dailyChallenge.ts` - Already sends notifications

**Verify existing implementation:**
```typescript
// In onDailyChallengeCreated trigger
export const onDailyChallengeCreated = onDocumentCreated(
  "dailyChallenges/{dateId}",
  async (event) => {
    const dateId = event.params.dateId;

    // Send FCM notifications to all users
    await sendDailyChallengeNotification(dateId);
  }
);
```

**Enhance notification payload:**
```typescript
const message = {
  notification: {
    title: "🐝 New Daily Challenge!",
    body: "A new puzzle is ready. Can you beat today's challenge?",
  },
  data: {
    type: "daily_challenge",
    route: "/daily-challenge",
    dateId: dateId,
  },
};
```

**App navigation (already implemented in Track 6):**
```dart
void _navigateFromNotification(RemoteMessage message) {
  final type = message.data['type'];

  if (type == 'daily_challenge') {
    _navigatorKey.currentState?.pushNamed('/daily-challenge');
  }
}
```

### Task 4: Social Sharing

**Files to create:**
- `lib/presentation/widgets/daily_challenge_completion_dialog.dart`
- `lib/services/share_service.dart`

**Implementation:**
```dart
class DailyChallengeCompletionDialog extends StatelessWidget {
  final DailyChallengeCompletion completion;
  final String dateId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('🎉 Challenge Complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐ ${completion.stars} stars'),
          Text('⏱️ ${_formatTime(completion.completionTimeMs)}'),
          Text('🏆 Rank: #${completion.rank}'),
          SizedBox(height: 24),
          Text('Share your result:'),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareButton(
                icon: Icons.share,
                label: 'Twitter',
                onTap: () => _shareToTwitter(context),
              ),
              _ShareButton(
                icon: Icons.share,
                label: 'Misskey',
                onTap: () => _shareToMisskey(context),
              ),
              _ShareButton(
                icon: Icons.share,
                label: 'Facebook',
                onTap: () => _shareToFacebook(context),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  Future<void> _shareToTwitter(BuildContext context) async {
    final text = '🐝 I completed today\'s HexBuzz challenge in ${_formatTime(completion.completionTimeMs)}! ⭐${completion.stars}/3\n\nCan you beat my time?\n\nhttps://hexbuzz.app/daily/$dateId';

    final url = Uri.https('twitter.com', '/intent/tweet', {
      'text': text,
      'hashtags': 'HexBuzz,DailyChallenge',
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareToMisskey(BuildContext context) async {
    final text = '🐝 I completed today\'s HexBuzz challenge in ${_formatTime(completion.completionTimeMs)}! ⭐${completion.stars}/3\n\nCan you beat my time?\n\nhttps://hexbuzz.app/daily/$dateId';

    // Show Misskey instance picker
    final instance = await _showMisskeyInstancePicker(context);
    if (instance == null) return;

    final url = Uri.https(instance, '/share', {
      'text': text,
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareToFacebook(BuildContext context) async {
    final url = Uri.https('hexbuzz.app', '/daily/$dateId');

    final shareUrl = Uri.https('www.facebook.com', '/sharer/sharer.php', {
      'u': url.toString(),
      'quote': '🐝 I completed today\'s HexBuzz challenge in ${_formatTime(completion.completionTimeMs)}! ⭐${completion.stars}/3',
    });

    if (await canLaunchUrl(shareUrl)) {
      await launchUrl(shareUrl, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }
}
```

### Task 5: Post-Completion UX

**Files to modify:**
- `lib/presentation/screens/daily_challenge_screen.dart`

**Implementation:**
```dart
class DailyChallengeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyChallengeProvider);

    return state.when(
      loading: () => LoadingIndicator(),

      notStarted: (challenge) => Column(
        children: [
          Text('Today\'s Challenge'),
          ElevatedButton(
            onPressed: () => ref.read(dailyChallengeProvider.notifier).start(),
            child: Text('Start Challenge'),
          ),
        ],
      ),

      playing: (challenge, startTime, path) => GameBoard(
        level: challenge.level,
        onComplete: () => ref.read(dailyChallengeProvider.notifier).complete(),
        showTimer: true,
        startTime: startTime,
        canRestart: false, // IMPORTANT: Cannot restart
      ),

      suspended: (challenge, startTime, path) => Column(
        children: [
          Text('Challenge Paused'),
          Text('Timer is still running!'),
          ElevatedButton(
            onPressed: () => ref.read(dailyChallengeProvider.notifier).resume(),
            child: Text('Resume'),
          ),
        ],
      ),

      completed: (completion) => Column(
        children: [
          // Show result only - no replay
          Text('✅ Challenge Completed!'),
          Text('⭐ ${completion.stars} stars'),
          Text('⏱️ ${_formatTime(completion.completionTimeMs)}'),
          Text('🏆 Rank: #${completion.rank}'),

          SizedBox(height: 24),

          // Show daily leaderboard
          DailyLeaderboard(dateId: completion.dateId),

          SizedBox(height: 24),

          // Share buttons
          Text('Share your result:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShareButton.twitter(completion: completion),
              ShareButton.misskey(completion: completion),
              ShareButton.facebook(completion: completion),
            ],
          ),

          SizedBox(height: 24),

          // No retry button - completed for today
          Text('Come back tomorrow for a new challenge!'),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Back to Menu'),
          ),
        ],
      ),

      error: (message) => ErrorDisplay(message: message),
    );
  }
}
```

### Task 6: Backend Validation

**Files to modify:**
- `functions/src/functions/dailyChallenge.ts`
- `firestore.rules`

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Daily challenges
    match /dailyChallenges/{dateId} {
      allow read: if true; // Anyone can read challenges
      allow write: if false; // Only Cloud Functions can write

      // Completions (entries)
      match /entries/{userId} {
        allow read: if true; // Anyone can read leaderboard

        // Only allow write if:
        // 1. User is authenticated
        // 2. userId matches authenticated user
        // 3. No existing completion for this user+date
        allow create: if request.auth != null
          && request.auth.uid == userId
          && !exists(/databases/$(database)/documents/dailyChallenges/$(dateId)/entries/$(userId));

        // No updates or deletes - completion is final
        allow update, delete: if false;
      }
    }
  }
}
```

**Cloud Function Validation:**
```typescript
export const validateDailyChallengeCompletion = onCall(async (request) => {
  const { dateId, stars, completionTimeMs } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check if already completed
  const existingCompletion = await db
    .collection('dailyChallenges')
    .doc(dateId)
    .collection('entries')
    .doc(userId)
    .get();

  if (existingCompletion.exists) {
    throw new HttpsError(
      'already-exists',
      'You have already completed today\'s challenge'
    );
  }

  // Validate completion data
  if (stars < 0 || stars > 3) {
    throw new HttpsError('invalid-argument', 'Invalid star count');
  }

  if (completionTimeMs < 1000) {
    throw new HttpsError('invalid-argument', 'Completion time too fast (suspicious)');
  }

  // Save completion
  await db
    .collection('dailyChallenges')
    .doc(dateId)
    .collection('entries')
    .doc(userId)
    .set({
      userId,
      stars,
      completionTimeMs,
      completedAt: new Date().toISOString(),
    });

  // Calculate rank
  const leaderboard = await db
    .collection('dailyChallenges')
    .doc(dateId)
    .collection('entries')
    .orderBy('stars', 'desc')
    .orderBy('completionTimeMs', 'asc')
    .get();

  const rank = leaderboard.docs.findIndex((doc) => doc.id === userId) + 1;

  return {
    success: true,
    rank,
    totalPlayers: leaderboard.size,
  };
});
```

## File Changes Summary

### New Files (4)
1. `lib/presentation/widgets/daily_challenge_completion_dialog.dart`
2. `lib/services/share_service.dart`
3. `lib/presentation/widgets/share_button.dart`
4. `lib/presentation/widgets/misskey_instance_picker.dart`

### Modified Files (8)
1. `lib/presentation/providers/daily_challenge_provider.dart` - One attempt enforcement
2. `lib/presentation/screens/daily_challenge_screen.dart` - Post-completion UX
3. `lib/data/firebase/firestore_daily_challenge_repository.dart` - Completion check
4. `lib/presentation/screens/front_screen.dart` - Remove global leaderboard button
5. `firestore.rules` - Prevent duplicate completions
6. `functions/src/functions/dailyChallenge.ts` - Backend validation
7. `pubspec.yaml` - Add url_launcher dependency
8. `lib/main.dart` - Already done (notification navigation)

### Deleted Files (2)
1. `lib/presentation/screens/leaderboard_screen.dart` - Global leaderboard removed
2. `lib/presentation/providers/leaderboard_provider.dart` - Global leaderboard removed

## Testing Checklist

- [ ] Cannot start challenge after completion
- [ ] Timer keeps running during suspend
- [ ] Cannot restart timer
- [ ] Only one completion per user per day (Firestore rules)
- [ ] Notification navigation works
- [ ] Share to Twitter works with correct text
- [ ] Share to Misskey works (with instance picker)
- [ ] Share to Facebook works
- [ ] Post-completion screen shows result only
- [ ] Daily leaderboard visible after completion
- [ ] Global leaderboard removed from app

## Dependencies

**Add to pubspec.yaml:**
```yaml
dependencies:
  url_launcher: ^6.2.3 # For social sharing
```

## Timeline

- Task 1 (One attempt): 2-3 hours
- Task 2 (Remove global): 1 hour
- Task 3 (Notifications): Already done ✅
- Task 4 (Social sharing): 3-4 hours
- Task 5 (Post-completion UX): 2-3 hours
- Task 6 (Backend validation): 2 hours

**Total: 10-13 hours**
