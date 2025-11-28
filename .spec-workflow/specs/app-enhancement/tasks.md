# Tasks Document: App Enhancement

## Phase 1: Core Infrastructure

- [x] 1. Update app branding to HexBuzz
  - Files: `lib/main.dart`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
  - Rename app from "Honeycomb One Pass" to "HexBuzz"
  - Update MaterialApp title and any hardcoded strings
  - Purpose: Establish new brand identity throughout the app
  - _Leverage: Existing main.dart structure_
  - _Requirements: REQ-2_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Rename the app from "Honeycomb One Pass" to "HexBuzz" across all configuration files and UI strings, following REQ-2. Update pubspec.yaml name/description, AndroidManifest.xml label, Info.plist bundle name, and MaterialApp title | Restrictions: Do not change package identifiers yet (com.example), only display names. Preserve all other configurations | Success: App displays "HexBuzz" in app launcher, title bar, and level selection header. Build succeeds on both platforms | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 2. Refine honeybee color palette in theme
  - File: `lib/presentation/theme/honey_theme.dart`
  - Update path gradient colors from blue/purple to amber/orange
  - Ensure visited cell colors use warm honey tones
  - Add contrast-compliant color utilities
  - Purpose: Create cohesive honeybee visual theme
  - _Leverage: Existing HoneyTheme class and color constants_
  - _Requirements: REQ-6, REQ-9_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter UI Developer | Task: Update HoneyTheme color palette per REQ-6 design spec. Replace any blue/purple colors with honeybee amber/orange palette. Path gradient should be #FFC107 → #FFB300 → #FF8F00. Add contrast utility methods for accessibility | Restrictions: Maintain existing color constant names for compatibility. Do not break existing widget references | Success: All game colors follow honeybee theme, no blue/purple visible, contrast ratios meet WCAG AA | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 3. Fix render layer ordering in HexGridPainter
  - File: `lib/presentation/widgets/hex_grid/hex_grid_widget.dart`
  - Reorder paint operations: cells → borders → visited → path → walls → checkpoints
  - Ensure checkpoint numbers render above path line
  - Purpose: Make checkpoints always visible above drawn path
  - _Leverage: Existing _HexGridPainter class_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter CustomPainter Developer | Task: Refactor _HexGridPainter.paint() to render layers in correct order per REQ-7: (1) cell backgrounds, (2) cell borders, (3) visited cell fills, (4) path line, (5) walls, (6) checkpoint numbers on top | Restrictions: Do not change cell/path rendering logic, only reorder draw calls. Preserve all existing visual elements | Success: Checkpoint numbers visible even when path crosses them. Visual comparison test passes | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 2: User Authentication

- [x] 4. Create User and AuthResult domain models
  - File: `lib/domain/models/user.dart`, `lib/domain/models/auth_result.dart`
  - Define User class with id, username, createdAt, isGuest
  - Define AuthResult class with success, user, errorMessage
  - Add JSON serialization for persistence
  - Purpose: Establish data models for authentication system
  - _Leverage: Existing model patterns (game_state.dart, progress_state.dart)_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create User and AuthResult models per design spec. User needs: id (String), username (String), createdAt (DateTime), isGuest (bool). AuthResult needs: success (bool), user (User?), errorMessage (String?). Include fromJson/toJson, copyWith, and equality | Restrictions: Follow existing model patterns. Use immutable classes. No external dependencies | Success: Models compile, serialize/deserialize correctly, unit tests pass | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 5. Create AuthRepository interface
  - File: `lib/domain/services/auth_repository.dart`
  - Define abstract interface for login, register, logout, getCurrentUser, authStateChanges
  - Purpose: Establish contract for authentication implementations
  - _Leverage: Existing ProgressRepository interface pattern_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Software Architect | Task: Create AuthRepository abstract class with methods: login(username, password) → Future<AuthResult>, register(username, password) → Future<AuthResult>, logout() → Future<void>, getCurrentUser() → Future<User?>, authStateChanges() → Stream<User?> | Restrictions: Interface only, no implementation. Follow existing repository patterns | Success: Interface compiles, methods match design spec | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 6. Implement LocalAuthRepository
  - File: `lib/data/local/local_auth_repository.dart`
  - Implement AuthRepository using SharedPreferences
  - Hash passwords using crypto package (SHA-256 + salt)
  - Store user data locally for offline/demo use
  - Purpose: Enable authentication without backend dependency
  - _Leverage: Existing LocalProgressRepository, SharedPreferences setup_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Backend Developer | Task: Implement LocalAuthRepository using SharedPreferences. Hash passwords with SHA-256 + random salt before storage. Store users as JSON in prefs. Implement all AuthRepository methods. Support guest user creation (isGuest=true) | Restrictions: Never store plaintext passwords. Use existing SharedPreferences instance from DI. Handle concurrent access safely | Success: Can register, login, logout. Passwords are hashed. Guest mode works. Unit tests pass | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 7. Create AuthProvider with Riverpod
  - File: `lib/presentation/providers/auth_provider.dart`
  - Create AsyncNotifier for auth state management
  - Expose login, register, logout, playAsGuest methods
  - Integrate with ProgressProvider for user-specific progress
  - Purpose: Provide reactive auth state to UI
  - _Leverage: Existing ProgressProvider pattern, Riverpod AsyncNotifier_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter State Management Developer | Task: Create AuthNotifier extending AsyncNotifier<User?>. Methods: login, register, logout, playAsGuest. On auth state change, trigger ProgressProvider to load/clear user progress. Use authRepository from ref.watch | Restrictions: Follow existing provider patterns. Handle loading/error states. No direct SharedPreferences access | Success: Auth state reactive, login/logout updates UI, progress loads per user | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 8. Create AuthScreen UI
  - File: `lib/presentation/screens/auth/auth_screen.dart`
  - Build login/register form with username/password fields
  - Add "Play as Guest" button
  - Include form validation (min lengths per REQ-5)
  - Apply honeybee theme styling
  - Purpose: Provide user authentication interface
  - _Leverage: HoneyTheme, existing screen patterns_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter UI Developer | Task: Create AuthScreen with login/register tabs or toggle. Username field (min 3 chars), password field (min 6 chars, obscured). "Play as Guest" button. Form validation with error messages. On success, navigate to LevelSelectScreen | Restrictions: Use HoneyTheme colors. Follow existing screen patterns. No hardcoded strings (prepare for i18n) | Success: Can register new user, login existing user, play as guest. Validation works. Honeybee themed | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 9. Update ProgressProvider for auth integration
  - File: `lib/presentation/providers/progress_provider.dart`
  - Load user-specific progress on login
  - Clear progress on logout
  - Support guest mode (local-only storage)
  - Purpose: Connect progress persistence to user accounts
  - _Leverage: Existing ProgressProvider, AuthProvider_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Modify ProgressNotifier to accept userId. On login, load progress for that user. On logout, clear state. For guest users (isGuest=true), use local storage keyed to "guest". Add method loadForUser(userId) | Restrictions: Maintain backward compatibility for existing progress. Don't lose guest progress on same device | Success: Each user has separate progress. Guest progress persists locally. Login loads correct progress | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 3: Front Screen and Navigation

- [x] 10. Create FrontScreen with branding
  - File: `lib/presentation/screens/front/front_screen.dart`
  - Display HexBuzz logo/title
  - Show "Tap to Start" prompt with subtle animation
  - Tap anywhere navigates to auth check (logged in → levels, else → auth)
  - Apply honeycomb background pattern
  - Purpose: Welcoming entry point for the app
  - _Leverage: HoneyTheme, navigation patterns_
  - _Requirements: REQ-3_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter UI Developer | Task: Create FrontScreen with centered HexBuzz title, honeycomb background, and animated "Tap to Start" text (pulsing opacity). GestureDetector on entire screen. Check auth state: if logged in go to LevelSelectScreen, else go to AuthScreen | Restrictions: Use HoneyTheme. Keep it simple and performant. Dispose animations properly | Success: Tapping navigates correctly based on auth state. Looks polished with honeybee theme | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 11. Update app navigation flow
  - File: `lib/main.dart`
  - Set FrontScreen as initial route
  - Add named routes for auth, levels, game screens
  - Implement screen transition animations
  - Purpose: Establish proper navigation hierarchy
  - _Leverage: Existing MaterialApp setup_
  - _Requirements: REQ-3, REQ-8_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Update main.dart to use FrontScreen as home. Add named routes: /auth, /levels, /game/:index. Use PageRouteBuilder for custom slide/fade transitions (300ms, Curves.easeInOut). Forward navigation slides left, back slides right | Restrictions: Preserve existing deep linking if any. Don't break game screen level loading | Success: Navigation flow: Front → Auth (if needed) → Levels → Game. Smooth transitions | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 4: Level Selection Enhancement

- [x] 12. Add time display to LevelCellWidget
  - File: `lib/presentation/widgets/level_cell/level_cell_widget.dart`
  - Display best completion time below stars
  - Format as MM:SS or SS.ss based on duration
  - Only show for completed levels
  - Purpose: Show player's best time on each level
  - _Leverage: Existing LevelCellWidget, ProgressState.bestTime_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Widget Developer | Task: Modify LevelCellWidget to accept bestTime parameter. Display formatted time below stars for completed levels. Format: if >=60s show "M:SS", else show "SS.ss". Use smaller font size than level number. Ensure contrast against cell background | Restrictions: Don't break existing star display. Keep cell aspect ratio. Handle null bestTime gracefully | Success: Completed levels show time, uncompleted don't. Format is correct. Looks good in grid | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 13. Improve star display contrast
  - File: `lib/presentation/widgets/level_cell/level_cell_widget.dart`
  - Add shadow/outline to empty stars for visibility
  - Ensure filled stars have strong contrast
  - Use design spec colors (#FFD700 filled, #BDBDBD empty with outline)
  - Purpose: Make stars clearly visible on all backgrounds
  - _Leverage: Existing star rendering in LevelCellWidget_
  - _Requirements: REQ-9_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter UI Developer | Task: Update star rendering in LevelCellWidget. Filled stars: #FFD700 with subtle drop shadow. Empty stars: #BDBDBD fill with 1px #757575 stroke or shadow. Ensure WCAG AA contrast on both unlocked (cream) and completed (gold) backgrounds | Restrictions: Keep star size proportional to cell. Don't change star count logic | Success: Stars visible on all cell states. Contrast meets accessibility standards | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 14. Update LevelSelectScreen header with new branding
  - File: `lib/presentation/screens/level_select/level_select_screen.dart`
  - Change title from "Honeycomb One Pass" to "HexBuzz"
  - Add logout button if user is logged in
  - Show username in header if logged in
  - Purpose: Reflect new branding and auth state
  - _Leverage: Existing header widget, AuthProvider_
  - _Requirements: REQ-2, REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter UI Developer | Task: Update LevelSelectScreen header. Change title to "HexBuzz". Watch AuthProvider state. If logged in, show "Hi, {username}" and logout icon button. On logout, navigate back to FrontScreen | Restrictions: Keep total stars display. Maintain header gradient styling | Success: Header shows HexBuzz, user greeting if logged in, logout works | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 5: Animations

- [x] 15. Create AnimatedCellPaint widget
  - File: `lib/presentation/widgets/animations/animated_cell_paint.dart`
  - Animate cell fill when visited (scale 0.8→1.0, opacity 0.0→1.0)
  - Duration 200ms with easeOutCubic curve
  - Purpose: Add satisfying feedback when cells are visited
  - _Leverage: Flutter AnimatedContainer or explicit animations_
  - _Requirements: REQ-8_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Animation Developer | Task: Create AnimatedCellPaint StatefulWidget. Props: isVisited (bool), child (Widget). When isVisited changes to true, animate scale from 0.8→1.0 and opacity 0.0→1.0 over 200ms with Curves.easeOutCubic. Properly dispose AnimationController | Restrictions: Efficient - many cells may animate. Don't block main thread | Success: Cells animate smoothly when visited. No jank. Proper cleanup | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 16. Integrate cell animation into HexGridWidget
  - File: `lib/presentation/widgets/hex_grid/hex_grid_widget.dart`
  - Wrap visited cell rendering with AnimatedCellPaint
  - Trigger animation when cell added to path
  - Purpose: Apply cell animations to game board
  - _Leverage: AnimatedCellPaint, existing HexGridWidget_
  - _Requirements: REQ-8_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Integrate AnimatedCellPaint into HexGridWidget. For each cell in path, wrap its paint with animation. Track which cells have already animated to avoid re-triggering. Consider using CustomPainter with animation or overlay widgets | Restrictions: Maintain 60fps. Don't animate already-visited cells on rebuild | Success: Cells pop nicely when visited. Smooth 60fps. No duplicate animations | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 17. Add button tap feedback animations
  - File: `lib/presentation/widgets/buttons/animated_button.dart`
  - Create reusable animated button wrapper
  - Scale to 0.95 on press, 1.0 on release
  - Duration 100ms each direction
  - Purpose: Provide tactile feedback for all buttons
  - _Leverage: GestureDetector, AnimatedScale_
  - _Requirements: REQ-8_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Widget Developer | Task: Create AnimatedButton widget that wraps any child. On tap down, scale to 0.95 over 100ms. On tap up/cancel, scale back to 1.0 over 100ms. Expose onTap callback. Use AnimatedScale or explicit controller | Restrictions: Must work with any child widget. Don't intercept other gestures | Success: Buttons feel tactile and responsive. Animation is subtle but noticeable | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 18. Enhance completion overlay animations
  - File: `lib/presentation/widgets/completion_overlay/completion_overlay.dart`
  - Add bounce effect to card appearance (elasticOut curve)
  - Stagger star animations with 150ms delay between each
  - Fade in buttons after stars complete
  - Purpose: Create delightful level completion celebration
  - _Leverage: Existing CompletionOverlay, TweenSequence_
  - _Requirements: REQ-8_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Animation Developer | Task: Enhance CompletionOverlay animations. Card: scale 0.8→1.0 with Curves.elasticOut over 400ms. Stars: sequential pop (0→1.3→0.9→1.0) with 150ms delay between each. Buttons: fade in 200ms after last star. Use AnimationController with multiple Tweens | Restrictions: Must look celebratory but not excessive. Properly dispose controllers | Success: Completion feels rewarding. Stars pop sequentially. Buttons appear smoothly | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 6: Asset Generation

- [x] 19. Create asset generation script
  - File: `tool/generate_assets.dart`
  - Connect to Automatic1111 API at localhost:7860
  - Generate 512x512 images from prompts
  - Save to assets/images/ directory
  - Purpose: Generate consistent game assets via Stable Diffusion
  - _Leverage: HTTP client, design spec prompts_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create CLI script tool/generate_assets.dart. Use http package to call Automatic1111 txt2img API. Config: width=512, height=512, steps=20, cfg_scale=7.0. Decode base64 response, save as PNG. Include prompts from design spec for: app_icon, level_button, lock_icon, star_filled, star_empty | Restrictions: Handle API errors gracefully. Don't overwrite existing assets without flag | Success: Running script generates all required assets. Images are 512x512 PNG | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [x] 20. Generate and integrate game assets
  - Files: `assets/images/*.png`, `pubspec.yaml`
  - Run generation script to create assets
  - Add assets to pubspec.yaml
  - Update widgets to use generated assets
  - Purpose: Replace placeholder graphics with generated assets
  - _Leverage: Asset generation script, Flutter Image widget_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Run asset generation script (requires local SD instance). Add generated images to pubspec.yaml assets section. Update FrontScreen to use app icon, LevelCellWidget to use level_button background and lock_icon, star display to use star icons. Provide fallback colors if images fail to load | Restrictions: Commit generated assets to repo. Handle missing asset gracefully | Success: App uses generated assets. Looks polished with consistent honeybee style | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

## Phase 7: Testing and Polish

- [x] 21. Write unit tests for auth system
  - File: `test/domain/services/local_auth_repository_test.dart`, `test/presentation/providers/auth_provider_test.dart`
  - Test registration, login, logout flows
  - Test password hashing
  - Test error cases
  - Purpose: Ensure auth reliability
  - _Leverage: Existing test patterns, mockito_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Test Developer | Task: Write unit tests for LocalAuthRepository and AuthProvider. Test cases: successful register, duplicate username error, successful login, wrong password error, logout clears state, guest mode, password is hashed (not plaintext in storage). Use mocktail for mocking | Restrictions: Tests must be independent. Mock SharedPreferences | Success: All auth flows tested. Password security verified. 90%+ coverage | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [ ] 22. Write widget tests for new screens
  - File: `test/presentation/screens/front_screen_test.dart`, `test/presentation/screens/auth_screen_test.dart`
  - Test FrontScreen tap navigation
  - Test AuthScreen form validation
  - Test navigation flows
  - Purpose: Ensure UI components work correctly
  - _Leverage: Flutter widget testing, ProviderScope_
  - _Requirements: REQ-3, REQ-5_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Test Developer | Task: Write widget tests for FrontScreen and AuthScreen. FrontScreen: renders title, tap navigates based on auth state. AuthScreen: form validates min lengths, shows errors, successful submission calls provider. Use pumpWidget with ProviderScope overrides | Restrictions: Mock providers. Test both success and failure paths | Success: Widget tests pass. Key interactions verified. No regressions | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [ ] 23. Write integration tests for complete user flows
  - File: `integration_test/app_test.dart`
  - Test: Launch → Front → Auth → Register → Levels → Play → Complete → Progress saved
  - Test: Guest flow with local-only progress
  - Purpose: Verify end-to-end functionality
  - _Leverage: Flutter integration_test package_
  - _Requirements: All_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write integration tests for full user journeys. Test 1: New user registers, plays level, completes, sees stars/time, progress persists on restart. Test 2: Guest plays, progress exists, simulated reinstall loses progress. Use integration_test package with flutter_driver | Restrictions: Tests should be reliable (no flaky timing). Reset state between tests | Success: Integration tests pass reliably. Critical paths verified | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_

- [ ] 24. Final polish and accessibility review
  - Files: Various
  - Verify all animations respect reduced-motion setting
  - Check color contrast throughout
  - Ensure touch targets are 44x44 minimum
  - Test with screen reader
  - Purpose: Ensure accessibility compliance
  - _Leverage: MediaQuery.disableAnimations, Semantics widgets_
  - _Requirements: REQ-8, REQ-9_
  - _Prompt: Implement the task for spec app-enhancement, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Accessibility Specialist | Task: Audit app for accessibility. Check MediaQuery.disableAnimations and skip animations if true. Verify all text contrast ≥4.5:1. Ensure interactive elements ≥44x44 logical pixels. Add Semantics labels to icons and buttons. Test with TalkBack/VoiceOver | Restrictions: Don't break existing functionality. Minimal visual changes | Success: App passes accessibility audit. Works with screen readers. Respects system settings | After completing: Mark task as [-] in progress before starting, use log-implementation tool with artifacts, then mark [x] complete_
