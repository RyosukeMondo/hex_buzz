# Daily Challenge Refinement - Requirements

## 1. Business Requirements

### 1.1 Problem Statement
The current daily challenge system allows unlimited retries, making the leaderboard unfair. Users who complete multiple attempts have an advantage over first-time players. The global leaderboard is redundant and dilutes focus from the daily competition.

### 1.2 Goals
- Create a fair competitive environment where everyone has exactly one attempt per day
- Increase user engagement through notifications and social sharing
- Simplify the experience by focusing only on daily challenges
- Enable viral growth through social media sharing

### 1.3 Success Metrics
- Daily challenge completion rate increases by 20%
- Social shares increase daily active users by 15%
- User retention (D1, D7, D30) improves
- Zero complaints about unfair leaderboard rankings
- 80% of users respond to daily challenge notifications

## 2. Functional Requirements

### 2.1 One Attempt Per Day
**Priority: Critical**

- **REQ-2.1.1:** Each user can complete the daily challenge exactly once per calendar day (UTC)
- **REQ-2.1.2:** Timer starts when user begins challenge and cannot be restarted
- **REQ-2.1.3:** User can suspend and resume challenge, but timer continues running
- **REQ-2.1.4:** Attempting to start an already-completed challenge shows completion result instead
- **REQ-2.1.5:** Backend validates no duplicate completions (security rule + Cloud Function)
- **REQ-2.1.6:** Suspicious completion times (<1 second) are rejected

### 2.2 Daily Leaderboard Only
**Priority: High**

- **REQ-2.2.1:** Global leaderboard UI is removed from application
- **REQ-2.2.2:** Only daily challenge leaderboard is visible
- **REQ-2.2.3:** Daily leaderboard shows rank, username, stars, and completion time
- **REQ-2.2.4:** Leaderboard updates in real-time as new completions arrive
- **REQ-2.2.5:** Current user's position is highlighted
- **REQ-2.2.6:** Top 3 positions show medal icons (🥇🥈🥉)

### 2.3 Notification System
**Priority: High**

- **REQ-2.3.1:** Users receive push notification when new daily challenge is available
- **REQ-2.3.2:** Notification title: "🐝 New Daily Challenge!"
- **REQ-2.3.3:** Notification body: "A new puzzle is ready. Can you beat today's challenge?"
- **REQ-2.3.4:** Tapping notification navigates directly to daily challenge screen
- **REQ-2.3.5:** Foreground notifications show as SnackBar with "View" action
- **REQ-2.3.6:** Notification sent automatically when daily challenge document created

### 2.4 Social Sharing
**Priority: High**

- **REQ-2.4.1:** After completion, user sees share buttons for Twitter, Misskey, Facebook
- **REQ-2.4.2:** Share text includes: completion time, stars earned, link to HexBuzz
- **REQ-2.4.3:** Share text format: "🐝 I completed today's HexBuzz challenge in {time}! ⭐{stars}/3\n\nCan you beat my time?\n\nhttps://hexbuzz.app/daily/{dateId}"
- **REQ-2.4.4:** Twitter share includes hashtags: #HexBuzz #DailyChallenge
- **REQ-2.4.5:** Misskey share shows instance picker (common instances + custom input)
- **REQ-2.4.6:** Facebook share uses Facebook Sharer with URL and quote
- **REQ-2.4.7:** All shares open in external browser/app
- **REQ-2.4.8:** Graceful fallback if social app not installed

### 2.5 Post-Completion UX
**Priority: Critical**

- **REQ-2.5.1:** After completion, show celebration dialog with stats
- **REQ-2.5.2:** Display user's stars, time, and rank
- **REQ-2.5.3:** Show daily leaderboard within completion dialog
- **REQ-2.5.4:** Display share buttons for all social platforms
- **REQ-2.5.5:** Show message: "Come back tomorrow for a new challenge!"
- **REQ-2.5.6:** No retry/restart button after completion
- **REQ-2.5.7:** "Back to Menu" button to exit
- **REQ-2.5.8:** Attempting to re-enter challenge shows same completion dialog

## 3. Technical Requirements

### 3.1 Backend Security
**Priority: Critical**

- **REQ-3.1.1:** Firestore security rule prevents duplicate entries per user per day
- **REQ-3.1.2:** Security rule allows read access to all challenge and entry documents
- **REQ-3.1.3:** Security rule prevents updates and deletes of completion entries
- **REQ-3.1.4:** Only Cloud Functions can create daily challenge documents
- **REQ-3.1.5:** Callable Cloud Function validates all completion submissions
- **REQ-3.1.6:** Function checks authentication, validates data, prevents duplicates
- **REQ-3.1.7:** Function calculates and returns accurate rank

### 3.2 State Management
**Priority: Critical**

- **REQ-3.2.1:** Daily challenge state is type-safe sealed union (freezed)
- **REQ-3.2.2:** States: loading, notStarted, playing, suspended, completed, alreadyCompleted, error
- **REQ-3.2.3:** State transitions are immutable and predictable
- **REQ-3.2.4:** Start time is preserved across suspend/resume (no restart)
- **REQ-3.2.5:** All state changes logged with DiagnosticLogger
- **REQ-3.2.6:** Provider uses Riverpod StateNotifier pattern

### 3.3 Data Structure
**Priority: High**

- **REQ-3.3.1:** Daily challenges stored at: `dailyChallenges/{YYYY-MM-DD}`
- **REQ-3.3.2:** Completions stored at: `dailyChallenges/{YYYY-MM-DD}/entries/{userId}`
- **REQ-3.3.3:** Completion document includes: userId, username, stars, completionTimeMs, completedAt
- **REQ-3.3.4:** Challenge document includes: id, createdAt, level, completionCount, notificationSent
- **REQ-3.3.5:** Leaderboard queries ordered by: stars DESC, completionTimeMs ASC
- **REQ-3.3.6:** Real-time updates via Firestore streams

### 3.4 Performance
**Priority: Medium**

- **REQ-3.4.1:** Leaderboard queries limited to 50 entries for performance
- **REQ-3.4.2:** Completion submission completes within 2 seconds
- **REQ-3.4.3:** Notification delivery within 5 minutes of challenge creation
- **REQ-3.4.4:** Screen loads within 1 second on mobile network
- **REQ-3.4.5:** Share dialogs open within 500ms

### 3.5 Testing
**Priority: High**

- **REQ-3.5.1:** Unit tests for all provider logic (100% coverage)
- **REQ-3.5.2:** Unit tests for Cloud Function validation (100% coverage)
- **REQ-3.5.3:** Widget tests for all new components
- **REQ-3.5.4:** Integration test for complete user flow
- **REQ-3.5.5:** Firestore security rules tested
- **REQ-3.5.6:** Manual test of notification flow
- **REQ-3.5.7:** All existing tests continue to pass

## 4. User Experience Requirements

### 4.1 User Journey - First Time
**Priority: High**

1. User receives notification about new daily challenge
2. User taps notification, navigates to daily challenge screen
3. Screen shows challenge preview and "Start Challenge" button
4. User taps start, timer begins, game board appears
5. User plays, can suspend/resume (timer keeps running)
6. User completes challenge
7. Celebration dialog appears with stats and share buttons
8. User shares result to social media
9. User views daily leaderboard showing their rank
10. User returns to menu

### 4.2 User Journey - Return Attempt (Same Day)
**Priority: Critical**

1. User navigates to daily challenge screen
2. Screen shows completion result (no start button)
3. Shows: "✅ Challenge Completed! ⭐X stars, ⏱️ Y time, 🏆 Rank #Z"
4. Shows daily leaderboard
5. Shows share buttons
6. Shows: "Come back tomorrow for a new challenge!"
7. No way to retry or restart

### 4.3 Visual Design
**Priority: Medium**

- **REQ-4.3.1:** Completion dialog uses celebration theme (confetti, animations)
- **REQ-4.3.2:** Share buttons show recognizable platform icons and colors
- **REQ-4.3.3:** Leaderboard highlights current user with distinct background
- **REQ-4.3.4:** Timer display is prominent and always visible during play
- **REQ-4.3.5:** Suspend/Resume buttons clearly labeled
- **REQ-4.3.6:** No restart/retry UI elements visible after completion

## 5. Non-Functional Requirements

### 5.1 Reliability
- System must prevent duplicate completions 99.9% of the time
- Notifications must deliver 95% of the time
- State management must handle network interruptions gracefully

### 5.2 Security
- All backend validation independent of client
- Firestore rules enforce one-attempt limit
- No sensitive data in social share links

### 5.3 Scalability
- Support 10,000+ simultaneous players per daily challenge
- Leaderboard queries performant up to 50,000 entries
- Notification system handles 100,000+ users

### 5.4 Maintainability
- Code follows project architecture patterns (SOLID, DI)
- Comprehensive logging for debugging
- Clear separation of concerns
- All code documented

### 5.5 Accessibility
- Share buttons have proper semantics
- Screen readers can announce completion status
- Tap targets meet minimum size requirements
- Color contrast meets WCAG AA standards

## 6. Constraints

### 6.1 Technical Constraints
- Must use Firebase Cloud Messaging for notifications
- Must use Firestore for data storage
- Must maintain backward compatibility with existing users
- Cannot break existing level progression features

### 6.2 Business Constraints
- No cost increase for Firebase usage
- Implementation completed within 2 weeks
- Zero downtime deployment
- Must support iOS, Android, and Web

## 7. Dependencies

### 7.1 External Dependencies
- Firebase Cloud Messaging (existing)
- Firestore (existing)
- url_launcher package (new)
- freezed package (existing)

### 7.2 Internal Dependencies
- Track 6 notification navigation implementation (completed)
- Existing daily challenge Cloud Functions (to be enhanced)
- DiagnosticLogger infrastructure (existing)
- Riverpod state management (existing)

## 8. Assumptions

- Users understand one-attempt-per-day is fair competition
- Users have internet connection to sync completion
- Push notifications are enabled on user devices
- Users are familiar with social media sharing

## 9. Out of Scope

- Offline mode for daily challenges
- Challenge history/archive beyond current day
- User profiles or achievements system
- Multiplayer or collaborative challenges
- In-app rewards or virtual currency
- Custom challenge creation by users

## 10. Acceptance Criteria

### 10.1 Must Have
- ✅ Users can complete daily challenge exactly once per day
- ✅ Timer cannot be restarted (can suspend/resume)
- ✅ Global leaderboard removed, only daily leaderboard visible
- ✅ Notifications sent when new challenge available
- ✅ Tap notification navigates to daily challenge
- ✅ Share buttons work for Twitter, Misskey, Facebook
- ✅ Post-completion: no retry possible, stats shown
- ✅ Backend prevents duplicate completions
- ✅ All tests pass

### 10.2 Should Have
- ✅ Real-time leaderboard updates
- ✅ Celebration animation on completion
- ✅ Share text includes time, stars, link
- ✅ Current user highlighted in leaderboard
- ✅ Comprehensive documentation

### 10.3 Nice to Have
- Confetti animation on completion
- Sound effects for completion
- Animated rank reveal
- Share preview image generation
- Daily challenge stats dashboard
