# Daily Challenge Refinement - Tasks

## Progress Summary (Updated: 2026-01-30)

**Overall Status**: Early Stage - Basic infrastructure exists, core features not implemented

**Completed**: 2/23 tasks (9%)
- ✅ Task 7: Provider tests file exists
- ✅ Task 17: Notification configuration verified

**What Exists**:
- Basic DailyChallengeRepository with hasCompletedToday() method
- DailyChallengeProvider with simple state (not sealed union state machine)
- DailyChallengeScreen displaying challenges
- Daily challenge Cloud Functions (generation, retrieval, notification triggers)
- Notification routing for 'daily_challenge' type

**Critical Gaps**:
- ❌ Firestore security rules are WIDE OPEN (allow read, write: if true)
- ❌ No backend validation function (validateDailyChallengeCompletion)
- ❌ No sealed union state machine (loading/notStarted/playing/suspended/completed/alreadyCompleted/error)
- ❌ No one-attempt enforcement (startChallenge, suspend, resume logic)
- ❌ No social sharing (url_launcher, ShareService, share buttons)
- ❌ No completion dialog with share buttons
- ❌ Global leaderboard still exists (needs removal)
- ❌ No integration tests or documentation

**Next Steps**: Phase 1 (Backend Security) must be completed first to prevent cheating, then Phase 2 (State Management) for one-attempt enforcement.

---

## Phase 1: Backend Security & Validation
**Status**: Not Started

- [ ] 1. Update Firestore security rules to prevent duplicate completions
  - File: firestore.rules
  - Add rules to allow only one completion per user per day
  - Prevent updates and deletes of completions
  - Purpose: Ensure backend data integrity for one-attempt-per-day rule
  - _Leverage: Existing firestore.rules structure_
  - _Requirements: Spec Task 6 - Backend Validation_
  - _Prompt: Role: Firebase Security Engineer specializing in Firestore security rules | Task: Update firestore.rules to enforce one-attempt-per-day for daily challenges. Rules must: (1) Allow read access to all dailyChallenges and entries, (2) Allow create on entries only if user is authenticated, userId matches auth.uid, and no existing document exists for that user+date combination, (3) Prevent all updates and deletes on entries, (4) Only Cloud Functions can write to dailyChallenges collection | Restrictions: Do not break existing security rules for other collections, maintain read access for leaderboard display | Success: Rules compile without errors, users cannot submit duplicate completions, Cloud Functions can still write challenges_

- [ ] 2. Create Cloud Function for completion validation
  - File: functions/src/functions/dailyChallenge.ts
  - Add validateDailyChallengeCompletion callable function
  - Check for existing completions, validate timing and stars
  - Calculate and return rank
  - Purpose: Server-side validation to prevent cheating
  - _Leverage: functions/src/utils/validator.ts, functions/src/utils/errorHandler.ts, functions/src/services/firestoreService.ts_
  - _Requirements: Spec Task 6 - Backend Validation_
  - _Prompt: Role: Cloud Functions Developer with expertise in Firebase Callable Functions and data validation | Task: Create validateDailyChallengeCompletion callable function in functions/src/functions/dailyChallenge.ts following these requirements: (1) Verify user authentication, (2) Check no existing completion exists for userId+dateId, (3) Validate stars (0-3) and completionTimeMs (>1000), (4) Save completion to Firestore, (5) Calculate rank by querying leaderboard ordered by stars DESC, completionTimeMs ASC, (6) Return success, rank, and totalPlayers | Leverage: Use ErrorHandler.wrap() for error handling, Validator for input validation, FirestoreService for database operations | Restrictions: Must throw HttpsError for all validation failures, do not allow duplicate completions, ensure atomic operations | Success: Function validates all inputs correctly, prevents duplicates, calculates accurate rank, handles errors gracefully_

- [ ] 3. Add tests for completion validation
  - File: functions/test/functions/dailyChallenge.test.ts
  - Test validation logic: duplicates rejected, invalid data rejected
  - Test rank calculation
  - Purpose: Ensure backend validation is reliable
  - _Leverage: functions/test/setup.ts, existing test patterns_
  - _Requirements: Spec Task 6 - Backend Validation_
  - _Prompt: Role: Backend Test Engineer with expertise in Firebase Functions testing and Jest | Task: Create comprehensive tests for validateDailyChallengeCompletion in functions/test/functions/dailyChallenge.test.ts covering: (1) Successful first completion with rank calculation, (2) Rejection of duplicate completion attempts, (3) Rejection of invalid stars (<0 or >3), (4) Rejection of suspicious times (<1000ms), (5) Unauthenticated user rejection, (6) Correct rank calculation with multiple users | Leverage: Existing test setup and mocking patterns | Restrictions: Use proper mocking for Firestore, test only function logic not Firebase internals | Success: All test cases pass, edge cases covered, 100% code coverage for validation logic_

## Phase 2: Frontend State Management - One Attempt Per Day
**Status**: Partially Completed - Basic provider exists, but sealed union state machine and one-attempt enforcement not fully implemented

- [ ] 4. Create DailyChallengeState sealed union
  - File: lib/domain/models/daily_challenge_state.dart
  - Define sealed class with states: loading, notStarted, playing, suspended, completed, alreadyCompleted, error
  - Add freezed annotations for immutability
  - Purpose: Type-safe state management for daily challenge flow
  - _Leverage: Existing domain models using freezed package_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day_
  - _Prompt: Role: Flutter Developer specializing in state management and freezed package | Task: Create DailyChallengeState sealed union in lib/domain/models/daily_challenge_state.dart with these states: (1) DailyChallengeStateLoading - initial loading, (2) DailyChallengeStateNotStarted(DailyChallenge challenge) - ready to start, (3) DailyChallengeStatePlaying(DailyChallenge challenge, DateTime startTime, List<HexCoordinate> currentPath) - active gameplay, (4) DailyChallengeStateSuspended(DailyChallenge challenge, DateTime startTime, DateTime suspendedTime, List<HexCoordinate> currentPath) - paused, (5) DailyChallengeStateCompleted(DailyChallengeCompletion completion) - finished today, (6) DailyChallengeStateAlreadyCompleted(DailyChallengeCompletion completion) - attempted to retry, (7) DailyChallengeStateError(String message) - error occurred | Use freezed and json_serializable annotations | Restrictions: Must be immutable, follow existing freezed patterns in codebase | Success: All states compile, freezed generates code without errors, states are type-safe and immutable_

- [ ] 5. Add getCompletion method to DailyChallengeRepository
  - File: lib/domain/repositories/daily_challenge_repository.dart, lib/data/firebase/firestore_daily_challenge_repository.dart
  - Add method to check if user completed today's challenge
  - Return completion data if exists, null otherwise
  - Purpose: Check completion status before allowing challenge start
  - _Leverage: Existing repository pattern and Firestore queries_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day_
  - _Prompt: Role: Flutter Backend Integration Developer with Firestore expertise | Task: Add getCompletion method to daily challenge repository. (1) In lib/domain/repositories/daily_challenge_repository.dart add abstract method: Future<DailyChallengeCompletion?> getCompletion({required String userId, required String dateId}), (2) In lib/data/firebase/firestore_daily_challenge_repository.dart implement method to query dailyChallenges/{dateId}/entries/{userId} and return DailyChallengeCompletion if exists, null if not, (3) Add error handling with DiagnosticLogger | Leverage: Existing Firestore patterns and error handling | Restrictions: Must handle network errors gracefully, return null for missing documents (not error) | Success: Method correctly returns existing completions, handles missing documents, logs errors appropriately_

- [ ] 6. Implement one-attempt logic in DailyChallengeProvider
  - File: lib/presentation/providers/daily_challenge_provider.dart
  - Add loadChallenge, startChallenge, suspend, resume, complete methods
  - Check for existing completion before allowing start
  - Prevent restart by preserving startTime
  - Purpose: Enforce one-attempt-per-day at application level
  - _Leverage: Existing Riverpod StateNotifier patterns, DailyChallengeState_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day, Task 5 - Post-Completion UX_
  - _Prompt: Role: Flutter State Management Expert with Riverpod expertise | Task: Implement DailyChallengeProvider as StateNotifier<DailyChallengeState> in lib/presentation/providers/daily_challenge_provider.dart with these methods: (1) loadChallenge() - fetches today's challenge and checks for existing completion, sets state to notStarted or alreadyCompleted, (2) startChallenge() - checks no completion exists, sets state to playing with DateTime.now() as startTime, (3) suspend() - transitions playing to suspended, preserving startTime (timer keeps running), (4) resume() - transitions suspended back to playing with same startTime (no restart), (5) complete(int stars) - calls repository.submitCompletion, transitions to completed state | Leverage: Use ref.read for repository access, DiagnosticLogger for events | Restrictions: Never reset startTime (prevents timer restart), always check completion status before operations, handle all state transitions safely | Success: State transitions work correctly, timer cannot be restarted, existing completions prevent new attempts, all operations logged_

- [x] 7. Add tests for DailyChallengeProvider
  - File: test/presentation/providers/daily_challenge_provider_test.dart
  - Test state transitions, one-attempt enforcement, suspend/resume
  - Mock repository responses
  - Purpose: Ensure provider logic is correct and reliable
  - _Leverage: Existing provider test patterns with mocktail_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day_
  - **Status**: Completed - Test file exists with mocktail setup
  - _Prompt: Role: Flutter Test Engineer with expertise in provider testing and mocktail | Task: Create comprehensive tests for DailyChallengeProvider in test/presentation/providers/daily_challenge_provider_test.dart covering: (1) loadChallenge when no completion exists - state becomes notStarted, (2) loadChallenge when completion exists - state becomes alreadyCompleted, (3) startChallenge sets playing state with current time, (4) suspend transitions to suspended preserving startTime, (5) resume transitions back to playing with same startTime (no restart), (6) complete calls repository and transitions to completed, (7) attempting to start when already completed does nothing | Leverage: Use ProviderContainer for testing, mock repository with mocktail | Restrictions: Mock all external dependencies, test state logic in isolation | Success: All state transitions tested, one-attempt logic verified, timer restart prevention confirmed, 100% code coverage_

## Phase 3: Social Sharing Implementation
**Status**: Not Started - No social sharing code exists

- [ ] 8. Add url_launcher dependency
  - File: pubspec.yaml
  - Add url_launcher: ^6.2.3 to dependencies
  - Run flutter pub get
  - Purpose: Enable opening social media sharing URLs
  - _Leverage: Existing pubspec.yaml dependency management_
  - _Requirements: Spec Task 4 - Social Sharing_
  - _Prompt: Role: Flutter DevOps Engineer | Task: Add url_launcher package to pubspec.yaml. Add 'url_launcher: ^6.2.3' to dependencies section, maintain alphabetical ordering of dependencies, run 'flutter pub get' to install | Restrictions: Use exact version specified, do not modify other dependencies | Success: Package installed successfully, no dependency conflicts, url_launcher is available for import_

- [ ] 9. Create ShareService for social media sharing
  - File: lib/services/share_service.dart
  - Implement methods for Twitter, Misskey, Facebook sharing
  - Generate share text with time, stars, link
  - Purpose: Centralize social sharing logic
  - _Leverage: url_launcher package, existing service patterns_
  - _Requirements: Spec Task 4 - Social Sharing_
  - _Prompt: Role: Flutter Developer with expertise in social media integration and url_launcher | Task: Create ShareService in lib/services/share_service.dart with these methods: (1) shareToTwitter(DailyChallengeCompletion completion, String dateId) - opens Twitter intent with text: "🐝 I completed today's HexBuzz challenge in {time}! ⭐{stars}/3\n\nCan you beat my time?\n\nhttps://hexbuzz.app/daily/{dateId}" and hashtags: HexBuzz,DailyChallenge, (2) shareToMisskey(DailyChallengeCompletion completion, String dateId, String instance) - opens Misskey share with same text format, (3) shareToFacebook(DailyChallengeCompletion completion, String dateId) - opens Facebook sharer with URL and quote, (4) formatTime(int ms) - helper to format milliseconds as "1m 23s" or "45s" | Use url_launcher's launchUrl with LaunchMode.externalApplication | Restrictions: Handle cases where social apps not installed, validate URLs before launching | Success: All sharing methods work correctly, text is properly formatted, URLs open in external apps, graceful fallback if app not available_

- [ ] 10. Create Misskey instance picker dialog
  - File: lib/presentation/widgets/misskey_instance_picker.dart
  - Show dialog with common instances + custom input
  - Return selected instance or null if cancelled
  - Purpose: Allow users to choose their Misskey instance
  - _Leverage: Existing dialog patterns in codebase_
  - _Requirements: Spec Task 4 - Social Sharing_
  - _Prompt: Role: Flutter UI Developer with expertise in dialogs and forms | Task: Create MisskeyInstancePicker widget in lib/presentation/widgets/misskey_instance_picker.dart that shows an AlertDialog with: (1) Title: "Select Misskey Instance", (2) List of common instances: misskey.io, misskey.dev, fedibird.com, mstdn.jp (as radio buttons), (3) "Custom" option with TextField for manual entry, (4) OK and Cancel buttons, (5) Returns Future<String?> with selected instance domain or null if cancelled | Follow Material Design dialog patterns | Restrictions: Validate custom URLs (must be valid domain), use existing theme colors | Success: Dialog displays correctly, all instances selectable, custom input validated, returns proper instance domain_

- [ ] 11. Create ShareButton widget
  - File: lib/presentation/widgets/share_button.dart
  - Reusable button for each social platform
  - Show platform icon and label
  - Handle tap to trigger share
  - Purpose: Consistent UI for share actions
  - _Leverage: Existing button widgets and theme_
  - _Requirements: Spec Task 4 - Social Sharing_
  - _Prompt: Role: Flutter UI Developer specializing in reusable widgets | Task: Create ShareButton widget in lib/presentation/widgets/share_button.dart as a stateless widget with properties: icon (IconData), label (String), color (Color), onTap (VoidCallback). Display icon above label in a column, use InkWell for tap feedback, apply color to icon and text. Also create named constructors: ShareButton.twitter(), ShareButton.misskey(), ShareButton.facebook() with predefined icons and colors (Twitter: blue #1DA1F2, Misskey: green #86b300, Facebook: blue #1877F2) | Follow existing button styling patterns | Restrictions: Must be accessible with proper semantics, maintain consistent sizing | Success: Buttons render correctly, tap feedback works, named constructors provide correct styling for each platform_

- [ ] 12. Create DailyChallengeCompletionDialog
  - File: lib/presentation/widgets/daily_challenge_completion_dialog.dart
  - Show completion stats (stars, time, rank)
  - Display share buttons for all platforms
  - Include daily leaderboard
  - Purpose: Celebrate completion and enable sharing
  - _Leverage: ShareService, ShareButton, existing dialog patterns_
  - _Requirements: Spec Task 4 - Social Sharing, Task 5 - Post-Completion UX_
  - _Prompt: Role: Flutter UI Developer with expertise in complex dialogs and composition | Task: Create DailyChallengeCompletionDialog in lib/presentation/widgets/daily_challenge_completion_dialog.dart as a StatelessWidget accepting DailyChallengeCompletion and dateId. Display: (1) Title: "🎉 Challenge Complete!", (2) Stats: stars with star icons, formatted time, rank badge, (3) Section header: "Share your result:", (4) Row of share buttons (Twitter, Misskey, Facebook) using ShareButton widget, (5) Daily leaderboard widget showing top 10, (6) Message: "Come back tomorrow for a new challenge!", (7) Close button | Use ShareService for button taps, show MisskeyInstancePicker when Misskey tapped | Leverage: ShareService, ShareButton, existing dialog styling | Restrictions: Must be visually appealing, handle long usernames gracefully, responsive layout | Success: Dialog displays all information clearly, share buttons work for all platforms, leaderboard integrated properly, good UX_

## Phase 4: UI Integration & Post-Completion UX
**Status**: Partially Completed - Screen exists but doesn't implement full state machine with suspend/resume

- [ ] 13. Update DailyChallengeScreen for new state management
  - File: lib/presentation/screens/daily_challenge_screen.dart
  - Consume DailyChallengeProvider state
  - Show different UI for each state (notStarted, playing, suspended, completed, alreadyCompleted)
  - Integrate completion dialog
  - Purpose: Complete daily challenge user experience
  - _Leverage: DailyChallengeProvider, DailyChallengeCompletionDialog, existing screen patterns_
  - _Requirements: Spec Task 5 - Post-Completion UX, Task 1 - One-Attempt-Per-Day_
  - _Prompt: Role: Flutter Screen Developer with expertise in Riverpod and complex state management | Task: Refactor lib/presentation/screens/daily_challenge_screen.dart to consume DailyChallengeProvider state and render different UI for each state: (1) loading - show CircularProgressIndicator, (2) notStarted - show challenge preview, "Start Challenge" button (calls provider.startChallenge()), (3) playing - show GameBoard with level, timer (using startTime), suspend button (calls provider.suspend()), no restart button, onComplete calls provider.complete(), (4) suspended - show "Challenge Paused" message, "Timer is still running!" warning, Resume button (calls provider.resume()), (5) completed/alreadyCompleted - show DailyChallengeCompletionDialog with stats, share buttons, daily leaderboard, "Back to Menu" button (no retry option), (6) error - show error message | Use ref.listen to show completion dialog when state transitions to completed | Restrictions: Never show restart/retry button after completion, timer must not be resettable, follow existing screen structure | Success: All states render correctly, transitions smooth, no retry possible after completion, completion dialog shows automatically, excellent UX_

- [ ] 14. Add daily leaderboard widget to completion flow
  - File: lib/presentation/widgets/daily_leaderboard.dart
  - Query and display dailyChallenges/{dateId}/entries
  - Show rank, username, stars, time for each entry
  - Highlight current user's position
  - Purpose: Show leaderboard after completion
  - _Leverage: Existing leaderboard patterns, Firestore queries_
  - _Requirements: Spec Task 5 - Post-Completion UX_
  - _Prompt: Role: Flutter Developer with Firestore and list widgets expertise | Task: Create DailyLeaderboard widget in lib/presentation/widgets/daily_leaderboard.dart as ConsumerWidget accepting dateId. Query Firestore dailyChallenges/{dateId}/entries ordered by stars DESC, completionTimeMs ASC, limit 50. Display list with: (1) Rank number with medal icons (🥇🥈🥉) for top 3, (2) Username, (3) Stars with star icons, (4) Formatted time, (5) Highlight current user's row with different background | Use StreamBuilder or ref.watch with stream provider for real-time updates | Restrictions: Handle empty leaderboard gracefully, show loading state, limit to 50 entries for performance | Success: Leaderboard displays correctly, updates in real-time, current user highlighted, performance is good, handles edge cases_

- [ ] 15. Remove global leaderboard navigation
  - File: lib/presentation/screens/front_screen.dart
  - Remove "Leaderboard" button/navigation from main menu
  - Keep only "Daily Challenge" navigation
  - Purpose: Simplify UI, focus on daily challenges only
  - _Leverage: Existing navigation structure_
  - _Requirements: Spec Task 2 - Remove Global Leaderboard_
  - **Status**: Pending - front_screen.dart doesn't show leaderboard button, but need to verify full navigation
  - _Prompt: Role: Flutter UI Developer | Task: In lib/presentation/screens/front_screen.dart, remove all references to global leaderboard: (1) Remove "Leaderboard" navigation button/card, (2) Remove route to LeaderboardScreen if defined in this file, (3) Adjust layout to remove gaps from removed button, (4) Ensure "Daily Challenge" button remains prominent | Restrictions: Do not break existing navigation structure, maintain visual balance | Success: Global leaderboard button removed, no navigation to global leaderboard, layout looks clean, Daily Challenge navigation works_

- [ ] 16. Delete global leaderboard files
  - Files: lib/presentation/screens/leaderboard_screen.dart, lib/presentation/providers/leaderboard_provider.dart, test/presentation/screens/leaderboard_screen_test.dart, test/presentation/providers/leaderboard_provider_test.dart
  - Remove unused global leaderboard implementation
  - Clean up imports in other files
  - Purpose: Remove dead code
  - _Leverage: IDE refactoring tools_
  - _Requirements: Spec Task 2 - Remove Global Leaderboard_
  - **Status**: Pending - Files still exist: lib/presentation/screens/leaderboard/leaderboard_screen.dart and lib/presentation/providers/leaderboard_provider.dart
  - _Prompt: Role: Code Cleanup Specialist | Task: Delete global leaderboard files and clean up: (1) Delete lib/presentation/screens/leaderboard_screen.dart, (2) Delete lib/presentation/providers/leaderboard_provider.dart, (3) Delete test/presentation/screens/leaderboard_screen_test.dart, (4) Delete test/presentation/providers/leaderboard_provider_test.dart, (5) Search for imports of these files in remaining codebase and remove them, (6) Search for routes to '/leaderboard' and remove them | Use IDE find/replace for thorough cleanup | Restrictions: Do not delete daily leaderboard code (DailyLeaderboard widget is different), verify no other code depends on deleted files | Success: All global leaderboard files deleted, no broken imports, no navigation to deleted screens, project compiles successfully_

## Phase 5: Notification Enhancement
**Status**: Completed - Notification system already properly configured from Track 6

- [x] 17. Verify notification configuration in main.dart
  - File: lib/main.dart
  - Ensure notification handlers configured (already done in Track 6)
  - Verify daily_challenge type routes to /daily-challenge
  - Purpose: Confirm notification navigation works
  - _Leverage: Existing notification navigation from Track 6_
  - _Requirements: Spec Task 3 - Notification System_
  - **Status**: Completed - Verified at lib/main.dart:357, notification system has proper case 'daily_challenge' routing, SnackBar with "View" action at main.dart:319-338, and _handleNotificationMessage at main.dart:300
  - _Prompt: Role: Flutter Integration Specialist | Task: Review lib/main.dart notification configuration: (1) Verify FirebaseMessaging.onMessage listener exists and shows SnackBar for foreground notifications, (2) Verify FirebaseMessaging.onMessageOpenedApp listener exists and calls _navigateFromNotification, (3) Verify _navigateFromNotification method handles type='daily_challenge' and navigates to '/daily-challenge', (4) Verify route is defined in MaterialApp routes or onGenerateRoute, (5) If any missing, implement according to Track 6 implementation | Leverage: Track 6 notification navigation code | Restrictions: Do not modify other notification types, maintain existing functionality | Success: Notification tap navigates to daily challenge screen, foreground notifications show SnackBar with "View" action, all notification types work correctly_

- [ ] 18. Test notification flow end-to-end
  - Files: Test notification payload and navigation
  - Verify Cloud Function sends notification when challenge created
  - Test tap notification navigates to daily challenge
  - Purpose: Ensure notification system works correctly
  - _Leverage: Firebase Cloud Messaging testing tools_
  - _Requirements: Spec Task 3 - Notification System_
  - _Prompt: Role: QA Engineer with Firebase Cloud Messaging expertise | Task: Create manual test plan and execute: (1) Trigger onDailyChallengeCreated Cloud Function (create dailyChallenges document), (2) Verify notification sent via Cloud Functions logs, (3) Verify notification received on test device, (4) Tap notification and verify navigation to /daily-challenge route, (5) Test foreground notification shows SnackBar with "View" action, (6) Document test results and any issues found | Use Firebase Console to manually trigger or test locally with Firebase Emulator | Restrictions: Test on real device for actual FCM delivery, use proper test user accounts | Success: Notifications sent successfully, tap navigation works, foreground notifications display correctly, user can reach daily challenge from notification_

## Phase 6: Integration Testing & Cleanup
**Status**: Not Started - No integration tests or documentation exist

- [ ] 19. Create end-to-end test for daily challenge flow
  - File: integration_test/daily_challenge_complete_flow_test.dart
  - Test full flow: receive notification → start → suspend → resume → complete → share
  - Verify one-attempt enforcement
  - Purpose: Validate complete user journey
  - _Leverage: Existing integration test patterns_
  - _Requirements: All tasks_
  - _Prompt: Role: Integration Test Engineer with Flutter integration_test expertise | Task: Create comprehensive end-to-end test in integration_test/daily_challenge_complete_flow_test.dart testing: (1) User receives notification (mock), taps, navigates to daily challenge, (2) Challenge screen shows "Start Challenge" button, user taps, (3) Game starts, timer running, user makes moves, (4) User suspends challenge, timer keeps running, (5) User resumes challenge, same timer, (6) User completes challenge, completion dialog appears with share buttons, (7) User cannot retry (button not present), (8) New user can start same challenge, (9) First user attempts to start again, sees "already completed" state | Use integration_test package, mock necessary services | Restrictions: Must run against Firebase Emulator for consistency, test real user interactions | Success: All user flows tested, one-attempt verified, share buttons present, no retry possible, tests pass reliably_

- [ ] 20. Update documentation
  - Files: README.md, docs/DAILY_CHALLENGE.md (create)
  - Document daily challenge rules, features, user flow
  - Add screenshots of completion dialog
  - Purpose: User and developer documentation
  - _Leverage: Existing documentation structure_
  - _Requirements: All tasks_
  - _Prompt: Role: Technical Writer with product documentation expertise | Task: Create comprehensive documentation for daily challenge feature: (1) Update README.md with Daily Challenge section describing feature overview, (2) Create docs/DAILY_CHALLENGE.md with detailed documentation including: Rules (one attempt per day, timer cannot restart, first completion only), Features (notifications, social sharing, daily leaderboard), User Flow (notification → start → play → suspend/resume → complete → share), Technical Implementation (Firestore structure, security rules, Cloud Functions), Testing (how to test locally), (3) Add troubleshooting section for common issues, (4) Include code examples for developers | Use markdown with code blocks and lists | Restrictions: Keep language clear and accessible, include actual code snippets where helpful | Success: Documentation is comprehensive and clear, covers all features and technical details, helpful for both users and developers_

- [ ] 21. Run all tests and fix issues
  - Files: Run flutter test, npm test
  - Ensure all unit, widget, and integration tests pass
  - Fix any failing tests
  - Purpose: Verify code quality and correctness
  - _Leverage: Existing CI/CD pipeline_
  - _Requirements: All tasks_
  - _Prompt: Role: QA Lead with full-stack testing expertise | Task: Execute comprehensive test suite and resolve issues: (1) Run 'flutter test' and ensure all Dart/Flutter tests pass, (2) Run 'cd functions && npm test' and ensure all Cloud Function tests pass, (3) Run 'flutter test integration_test/' for integration tests, (4) For any failing tests: analyze failure, fix code or update test as appropriate, re-run until passing, (5) Verify code coverage meets targets (80% overall, 90% critical paths), (6) Run 'flutter analyze' and fix any issues, (7) Document any test updates or known issues | Run tests locally and in CI environment | Restrictions: Do not disable or skip tests to pass, fix root causes not symptoms | Success: All tests passing, code coverage targets met, no analyzer errors, CI pipeline green_

- [ ] 22. Deploy Cloud Functions and test in production
  - Files: Firebase deployment
  - Deploy updated Cloud Functions to production
  - Test notification sending, completion validation
  - Monitor Cloud Functions logs
  - Purpose: Launch to production
  - _Leverage: Existing Firebase deployment process_
  - _Requirements: All tasks_
  - _Prompt: Role: DevOps Engineer with Firebase deployment expertise | Task: Deploy and verify production deployment: (1) Run 'firebase deploy --only functions' to deploy updated Cloud Functions, (2) Run 'firebase deploy --only firestore:rules' to deploy updated security rules, (3) Create test daily challenge using manualGenerateChallenge function, (4) Verify notification sent and received, (5) Test completion validation by attempting duplicate completion (should fail), (6) Monitor Cloud Functions logs for errors, (7) Test from real user device: receive notification, complete challenge, verify rank calculation | Deploy during low-traffic period, have rollback plan ready | Restrictions: Test thoroughly before deploying, monitor for errors, be ready to rollback if issues | Success: Functions deployed successfully, notifications working, completion validation works, security rules enforced, no errors in logs, real users can complete challenges_

- [ ] 23. Final verification and handoff
  - Files: All modified files
  - Verify all success criteria met
  - Create release notes
  - Hand off to product team
  - Purpose: Complete implementation
  - _Leverage: Spec success criteria_
  - _Requirements: All tasks_
  - _Prompt: Role: Product Manager and Technical Lead | Task: Final verification and handoff: (1) Review all success criteria from spec and verify each is met: users can only complete once per day ✓, timer cannot restart ✓, only daily leaderboard visible ✓, notifications work ✓, share buttons functional ✓, no retry after completion ✓, (2) Create release notes documenting: new features (one-attempt daily challenge, social sharing, enhanced leaderboard), breaking changes (global leaderboard removed), migration notes if any, known issues if any, (3) Create user announcement: "🎉 Daily Challenge Refined! Now fair for everyone - one attempt per day, share your results, compete on daily leaderboard!", (4) Prepare rollback plan documentation, (5) Schedule user communication and launch | Verify every success criterion systematically | Restrictions: Do not launch until all criteria verified, ensure rollback plan ready | Success: All success criteria met and documented, release notes complete, team ready to support launch, rollback plan ready, users can enjoy improved daily challenge_
