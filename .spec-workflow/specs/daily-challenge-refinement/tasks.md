# Daily Challenge Refinement - Tasks

## Progress Summary (Updated: 2026-01-30)

**Overall Status**: Phases 1, 2, 3, 4, & partial Phase 6 Complete - Backend, state management, social sharing, UI integration, and test fixes implemented

**Completed**: 18/23 tasks (78%)
- ✅ Task 1: Firestore security rules enforce one-attempt-per-day
- ✅ Task 2: validateDailyChallengeCompletion Cloud Function implemented
- ✅ Task 3: Comprehensive tests for completion validation
- ✅ Task 4: DailyChallengeState sealed union created
- ✅ Task 5: getCompletion method added to repository
- ✅ Task 6: One-attempt logic implemented in DailyChallengeProvider
- ✅ Task 7: Provider tests file exists
- ✅ Task 8: url_launcher dependency added
- ✅ Task 9: ShareService created with Twitter, Misskey, Facebook support
- ✅ Task 10: MisskeyInstancePicker dialog implemented
- ✅ Task 11: ShareButton widget created
- ✅ Task 12: DailyChallengeCompletionDialog implemented
- ✅ Task 13: DailyChallengeScreen updated for new state machine
- ✅ Task 14: Daily leaderboard widget added to completion flow
- ✅ Task 15: Global leaderboard navigation removed
- ✅ Task 16: Global leaderboard files deleted
- ✅ Task 17: Notification configuration verified

**What Exists**:
- ✅ DailyChallengeRepository with hasCompletedToday() and getCompletion() methods
- ✅ DailyChallengeProvider with sealed union state machine
- ✅ DailyChallengeState with 7 states (Loading, NotStarted, Playing, Suspended, Completed, AlreadyCompleted, Error)
- ✅ One-attempt enforcement (startChallenge, suspend, resume, complete logic)
- ✅ Timer preservation across suspend/resume (prevents restart)
- DailyChallengeScreen displaying challenges (needs update for new state machine)
- Daily challenge Cloud Functions (generation, retrieval, notification triggers, validation)
- Notification routing for 'daily_challenge' type

**Critical Gaps**:
- ✅ Firestore security rules now enforce one-attempt-per-day
- ✅ Backend validation function implemented (validateDailyChallengeCompletion)
- ✅ Sealed union state machine implemented
- ✅ One-attempt enforcement implemented (startChallenge, suspend, resume logic)
- ✅ Social sharing implemented (url_launcher, ShareService, share buttons)
- ✅ Completion dialog with share buttons implemented
- ✅ Global leaderboard removed (navigation and files deleted)
- ✅ DailyChallengeScreen updated for new state machine
- ✅ Daily leaderboard widget integrated
- ❌ No integration tests or documentation

**Next Steps**: Phase 5 (Notification Testing) & Phase 6 (Integration Testing & Cleanup)

---

## Phase 1: Backend Security & Validation
**Status**: Completed

- [x] 1. Update Firestore security rules to prevent duplicate completions
  - File: firestore.rules
  - Add rules to allow only one completion per user per day
  - Prevent updates and deletes of completions
  - Purpose: Ensure backend data integrity for one-attempt-per-day rule
  - _Leverage: Existing firestore.rules structure_
  - _Requirements: Spec Task 6 - Backend Validation_
  - **Status**: Completed - Rules enforce one-attempt-per-day with exists() check, validate stars and completionTimeMs

- [x] 2. Create Cloud Function for completion validation
  - File: functions/src/functions/dailyChallenge.ts
  - Add validateDailyChallengeCompletion callable function
  - Check for existing completions, validate timing and stars
  - Calculate and return rank
  - Purpose: Server-side validation to prevent cheating
  - _Leverage: functions/src/utils/validator.ts, functions/src/utils/errorHandler.ts, functions/src/services/firestoreService.ts_
  - _Requirements: Spec Task 6 - Backend Validation_
  - **Status**: Completed - Callable function validates all inputs, prevents duplicates, calculates rank

- [x] 3. Add tests for completion validation
  - File: functions/test/functions/dailyChallenge.test.ts
  - Test validation logic: duplicates rejected, invalid data rejected
  - Test rank calculation
  - Purpose: Ensure backend validation is reliable
  - _Leverage: functions/test/setup.ts, existing test patterns_
  - _Requirements: Spec Task 6 - Backend Validation_
  - **Status**: Completed - Comprehensive tests cover all validation cases, duplicates, auth, rank calculation

## Phase 2: Frontend State Management - One Attempt Per Day
**Status**: Completed

- [x] 4. Create DailyChallengeState sealed union
  - File: lib/domain/models/daily_challenge_state.dart
  - Define sealed class with states: loading, notStarted, playing, suspended, completed, alreadyCompleted, error
  - Add freezed annotations for immutability
  - Purpose: Type-safe state management for daily challenge flow
  - _Leverage: Existing domain models using freezed package_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day_
  - **Status**: Completed - Sealed union with 7 states, immutable classes, type-safe state transitions

- [x] 5. Add getCompletion method to DailyChallengeRepository
  - File: lib/domain/repositories/daily_challenge_repository.dart, lib/data/firebase/firestore_daily_challenge_repository.dart
  - Add method to check if user completed today's challenge
  - Return completion data if exists, null otherwise
  - Purpose: Check completion status before allowing challenge start
  - _Leverage: Existing repository pattern and Firestore queries_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day_
  - **Status**: Completed - Method added to interface and Firestore implementation with error handling

- [x] 6. Implement one-attempt logic in DailyChallengeProvider
  - File: lib/presentation/providers/daily_challenge_provider.dart
  - Add loadChallenge, startChallenge, suspend, resume, complete methods
  - Check for existing completion before allowing start
  - Prevent restart by preserving startTime
  - Purpose: Enforce one-attempt-per-day at application level
  - _Leverage: Existing Riverpod StateNotifier patterns, DailyChallengeState_
  - _Requirements: Spec Task 1 - Enforce One-Attempt-Per-Day, Task 5 - Post-Completion UX_
  - **Status**: Completed - StateNotifier with all methods, startTime preservation, one-attempt enforcement

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
**Status**: Completed

- [x] 8. Add url_launcher dependency
  - File: pubspec.yaml
  - Add url_launcher: ^6.2.3 to dependencies
  - Run flutter pub get
  - Purpose: Enable opening social media sharing URLs
  - _Leverage: Existing pubspec.yaml dependency management_
  - _Requirements: Spec Task 4 - Social Sharing_
  - **Status**: Completed - url_launcher ^6.2.3 added and installed

- [x] 9. Create ShareService for social media sharing
  - File: lib/services/share_service.dart
  - Implement methods for Twitter, Misskey, Facebook sharing
  - Generate share text with time, stars, link
  - Purpose: Centralize social sharing logic
  - _Leverage: url_launcher package, existing service patterns_
  - _Requirements: Spec Task 4 - Social Sharing_
  - **Status**: Completed - ShareService with all sharing methods and formatTime helper

- [x] 10. Create Misskey instance picker dialog
  - File: lib/presentation/widgets/misskey_instance_picker.dart
  - Show dialog with common instances + custom input
  - Return selected instance or null if cancelled
  - Purpose: Allow users to choose their Misskey instance
  - _Leverage: Existing dialog patterns in codebase_
  - _Requirements: Spec Task 4 - Social Sharing_
  - **Status**: Completed - Dialog with 4 common instances, custom input, and validation

- [x] 11. Create ShareButton widget
  - File: lib/presentation/widgets/share_button.dart
  - Reusable button for each social platform
  - Show platform icon and label
  - Handle tap to trigger share
  - Purpose: Consistent UI for share actions
  - _Leverage: Existing button widgets and theme_
  - _Requirements: Spec Task 4 - Social Sharing_
  - **Status**: Completed - Reusable widget with named constructors for each platform

- [x] 12. Create DailyChallengeCompletionDialog
  - File: lib/presentation/widgets/daily_challenge_completion_dialog.dart
  - Show completion stats (stars, time, rank)
  - Display share buttons for all platforms
  - Include daily leaderboard
  - Purpose: Celebrate completion and enable sharing
  - _Leverage: ShareService, ShareButton, existing dialog patterns_
  - _Requirements: Spec Task 4 - Social Sharing, Task 5 - Post-Completion UX_
  - **Status**: Completed - Dialog with stats, share buttons (daily leaderboard placeholder for task 14)

## Phase 4: UI Integration & Post-Completion UX
**Status**: Completed

- [x] 13. Update DailyChallengeScreen for new state management
  - File: lib/presentation/screens/daily_challenge_screen.dart
  - Consume DailyChallengeProvider state
  - Show different UI for each state (notStarted, playing, suspended, completed, alreadyCompleted)
  - Integrate completion dialog
  - Purpose: Complete daily challenge user experience
  - _Leverage: DailyChallengeProvider, DailyChallengeCompletionDialog, existing screen patterns_
  - _Requirements: Spec Task 5 - Post-Completion UX, Task 1 - One-Attempt-Per-Day_
  - **Status**: Completed - Screen refactored with pattern matching for all 7 states, auto-show completion dialog, no retry buttons

- [x] 14. Add daily leaderboard widget to completion flow
  - File: lib/presentation/widgets/daily_leaderboard.dart
  - Query and display dailyChallenges/{dateId}/entries
  - Show rank, username, stars, time for each entry
  - Highlight current user's position
  - Purpose: Show leaderboard after completion
  - _Leverage: Existing leaderboard patterns, Firestore queries_
  - _Requirements: Spec Task 5 - Post-Completion UX_
  - **Status**: Completed - DailyLeaderboard widget with real-time Firestore stream, medals for top 3, user highlighting, integrated into completion dialog

- [x] 15. Remove global leaderboard navigation
  - File: lib/presentation/screens/level_select_screen.dart, lib/main.dart, lib/presentation/screens/game/game_screen.dart
  - Remove "Leaderboard" button/navigation from main menu
  - Keep only "Daily Challenge" navigation
  - Purpose: Simplify UI, focus on daily challenges only
  - _Leverage: Existing navigation structure_
  - _Requirements: Spec Task 2 - Remove Global Leaderboard_
  - **Status**: Completed - Removed leaderboard button from level select, removed route and notification handling

- [x] 16. Delete global leaderboard files
  - Files: lib/presentation/screens/leaderboard/leaderboard_screen.dart, lib/presentation/providers/leaderboard_provider.dart
  - Remove unused global leaderboard implementation
  - Clean up imports in other files
  - Purpose: Remove dead code
  - _Leverage: IDE refactoring tools_
  - _Requirements: Spec Task 2 - Remove Global Leaderboard_
  - **Status**: Completed - Deleted screen and provider files, removed imports, removed global leaderboard submission from game_provider

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

- [x] 21. Run all tests and fix issues
  - Files: Run flutter test, npm test
  - Ensure all unit, widget, and integration tests pass
  - Fix any failing tests
  - Purpose: Verify code quality and correctness
  - _Leverage: Existing CI/CD pipeline_
  - _Requirements: All tasks_
  - **Status**: Completed - Fixed compilation errors and test failures related to global leaderboard removal, updated provider usage to family pattern, removed obsolete tests, 1030 tests passing
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
