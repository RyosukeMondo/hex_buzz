# Tasks Document: Level Selection UI & Game Polish

## Phase 1: Domain Models & Services (Pure Dart)

- [x] 1.1 Create ProgressState and LevelProgress models
  - File: `lib/domain/models/progress_state.dart`
  - Define immutable `LevelProgress` class with `completed`, `stars`, `bestTime`
  - Define `ProgressState` class with level map and computed properties
  - Include JSON serialization/deserialization
  - Purpose: Core data models for tracking player progress
  - _Leverage: Pattern from `lib/domain/models/game_state.dart`_
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer specializing in domain models | Task: Create ProgressState and LevelProgress immutable data classes with JSON serialization, following existing GameState patterns | Restrictions: No Flutter imports, pure Dart only, must be testable without framework | Success: Models compile, JSON round-trip works, `isUnlocked()` logic correct | Instructions: Set task 1.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [x] 1.2 Create StarCalculator service
  - File: `lib/domain/services/star_calculator.dart`
  - Implement time-to-stars conversion: 3★≤10s, 2★≤30s, 1★≤60s, 0★>60s
  - Pure function, no side effects
  - Purpose: Centralized star calculation logic
  - _Leverage: None (standalone utility)_
  - _Requirements: 3.1, 3.2, 3.3_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create StarCalculator with static method `calculateStars(Duration time)` returning 0-3 | Restrictions: Pure Dart, no dependencies, boundary conditions must be exact (10.000s = 3★, 10.001s = 2★) | Success: All threshold boundaries correct, function is pure | Instructions: Set task 1.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [x] 1.3 Create ProgressRepository interface
  - File: `lib/domain/services/progress_repository.dart`
  - Define abstract interface with `load()`, `save()`, `reset()` methods
  - Purpose: Abstract persistence interface for dependency injection
  - _Leverage: Pattern from `lib/domain/services/level_repository.dart`_
  - _Requirements: 2.5, 2.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer specializing in clean architecture | Task: Create abstract ProgressRepository interface with async methods for load/save/reset | Restrictions: Interface only, no implementation, no Flutter imports | Success: Interface compiles, methods return correct types | Instructions: Set task 1.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [x] 1.4 Write unit tests for domain models and services
  - Files: `test/domain/models/progress_state_test.dart`, `test/domain/services/star_calculator_test.dart`
  - Test ProgressState: `isUnlocked()`, `withLevelCompleted()`, JSON serialization
  - Test StarCalculator: all boundary conditions (9.99s, 10.00s, 10.01s, 29.99s, 30.00s, etc.)
  - Purpose: Ensure domain logic correctness
  - _Leverage: Testing patterns from `test/domain/models/game_state_test.dart`_
  - _Requirements: 3.1, 3.2, 3.3, Testability Requirements_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write comprehensive unit tests for ProgressState and StarCalculator with boundary condition coverage | Restrictions: Test pure Dart only, no Flutter test dependencies needed | Success: All tests pass, boundary conditions verified, >90% coverage | Instructions: Set task 1.4 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 2: Data Layer (Persistence)

- [x] 2.1 Add shared_preferences dependency
  - File: `pubspec.yaml`
  - Add `shared_preferences: ^2.2.0` to dependencies
  - Run `flutter pub get`
  - Purpose: Enable local storage for progress persistence
  - _Leverage: None_
  - _Requirements: 2.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Add shared_preferences dependency to pubspec.yaml and verify installation | Restrictions: Use stable version ^2.2.0, ensure compatibility | Success: `flutter pub get` succeeds, package available | Instructions: Set task 2.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [x] 2.2 Implement LocalProgressRepository
  - File: `lib/data/local/local_progress_repository.dart`
  - Implement `ProgressRepository` interface using `shared_preferences`
  - Handle corrupted data gracefully (return default state)
  - Purpose: Concrete persistence implementation
  - _Leverage: JSON serialization from ProgressState_
  - _Requirements: 2.5, 2.6, Error Handling scenarios_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer specializing in local storage | Task: Implement LocalProgressRepository using shared_preferences, with JSON serialization and error handling | Restrictions: Catch FormatException for corrupted data, return default state on errors | Success: Load/save/reset work correctly, corrupted data handled gracefully | Instructions: Set task 2.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [x] 2.3 Write integration tests for LocalProgressRepository
  - File: `test/data/local/local_progress_repository_test.dart`
  - Test save/load round-trip, corrupted data handling, reset functionality
  - Purpose: Ensure persistence reliability
  - _Leverage: shared_preferences_test package for mocking_
  - _Requirements: 2.5, 2.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write integration tests for LocalProgressRepository with mocked SharedPreferences | Restrictions: Mock SharedPreferences, test error scenarios | Success: All persistence scenarios tested, error handling verified | Instructions: Set task 2.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 3: Debug Layer (AI Agent-First)

- [-] 3.1 Create progress CLI command
  - File: `lib/debug/cli/commands/progress_command.dart`
  - Implement subcommands: `get`, `set --level N --stars S`, `reset`
  - Output JSON for AI agent parsing
  - Purpose: Enable CLI-based progress management for AI agents
  - _Leverage: Pattern from `lib/debug/cli/commands/validate_command.dart`_
  - _Requirements: 6.1, 6.2, 6.3_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: CLI Developer | Task: Create ProgressCommand with get/set/reset subcommands, JSON output | Restrictions: Follow existing CLI patterns, structured JSON output | Success: All subcommands work, JSON output parseable | Instructions: Set task 3.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 3.2 Register progress command in CLI runner
  - File: `lib/debug/cli/cli_runner.dart` (modify)
  - Add `ProgressCommand` to command list
  - Purpose: Make progress command available via CLI
  - _Leverage: Existing command registration pattern_
  - _Requirements: 6.1_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: CLI Developer | Task: Register ProgressCommand in CliRunner | Restrictions: Follow existing pattern, minimal changes | Success: `honeycomb-cli progress` works | Instructions: Set task 3.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 3.3 Create progress REST API routes
  - File: `lib/debug/api/routes/progress_routes.dart`
  - Implement: `GET /api/progress`, `POST /api/progress/complete`, `POST /api/progress/reset`
  - Purpose: Enable REST API-based progress management for AI agents
  - _Leverage: Pattern from `lib/debug/api/routes/level_routes.dart`_
  - _Requirements: 6.4, 6.5, 6.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: API Developer | Task: Create progress REST endpoints following existing route patterns | Restrictions: JSON request/response, follow existing API patterns | Success: All endpoints return correct data, status codes correct | Instructions: Set task 3.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 3.4 Register progress routes in server
  - File: `lib/debug/api/server.dart` (modify)
  - Mount progress routes on router
  - Purpose: Make progress API available
  - _Leverage: Existing route registration_
  - _Requirements: 6.4_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: API Developer | Task: Register progress routes in debug server | Restrictions: Follow existing mount pattern | Success: API endpoints accessible | Instructions: Set task 3.4 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 3.5 Write CLI and API tests
  - Files: `test/debug/cli/progress_command_test.dart`, `test/debug/api/progress_routes_test.dart`
  - Test all CLI subcommands and API endpoints
  - Purpose: Ensure debug interfaces work correctly
  - _Leverage: Test patterns from existing CLI/API tests_
  - _Requirements: 6.1-6.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write tests for progress CLI commands and REST API endpoints | Restrictions: Mock persistence layer, test all scenarios | Success: All debug interfaces tested, commands produce correct output | Instructions: Set task 3.5 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 4: Presentation Layer - State Management

- [ ] 4.1 Create ProgressNotifier provider
  - File: `lib/presentation/providers/progress_provider.dart`
  - Implement `AsyncNotifier<ProgressState>` with `completeLevel()`, `resetProgress()`
  - Wire to `ProgressRepository` and `StarCalculator`
  - Purpose: Reactive state management for progress
  - _Leverage: Pattern from `lib/presentation/providers/game_provider.dart`_
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer specializing in Riverpod | Task: Create ProgressNotifier with async state management, integrating StarCalculator and ProgressRepository | Restrictions: Follow existing provider patterns, handle loading/error states | Success: Provider compiles, state updates correctly on level completion | Instructions: Set task 4.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 4.2 Integrate progress provider with game flow
  - File: `lib/presentation/providers/game_provider.dart` (modify)
  - Add `currentLevelIndex` tracking
  - Call `progressProvider.completeLevel()` on game completion
  - Purpose: Connect game completion to progress tracking
  - _Leverage: Existing GameNotifier_
  - _Requirements: 2.2, 3.1, 3.2_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Modify GameNotifier to track level index and trigger progress updates on completion | Restrictions: Minimal changes, maintain existing functionality | Success: Progress updated when level completed, level index tracked | Instructions: Set task 4.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 4.3 Initialize progress provider in main.dart
  - File: `lib/main.dart` (modify)
  - Load LocalProgressRepository at startup
  - Override progressRepositoryProvider
  - Purpose: Ensure progress is loaded before app starts
  - _Leverage: Pattern from levelRepositoryProvider initialization_
  - _Requirements: 2.5_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Initialize LocalProgressRepository in main.dart and inject via provider override | Restrictions: Follow existing initialization pattern | Success: Progress loads on app start, provider available throughout app | Instructions: Set task 4.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 5: Presentation Layer - Theme

- [ ] 5.1 Create HoneyTheme
  - File: `lib/presentation/theme/honey_theme.dart`
  - Define color constants: honeyGold, deepHoney, warmCream, brownAccent
  - Create `ThemeData` with honey styling
  - Add custom decorations for honeycomb cells
  - Purpose: Centralized honey/bee theme styling
  - _Leverage: Existing Colors from `lib/presentation/widgets/hex_grid/hex_cell_widget.dart`_
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: UI/UX Developer specializing in theming | Task: Create HoneyTheme with color palette and ThemeData following design specs | Restrictions: Use exact color codes from requirements, ensure WCAG AA contrast | Success: Theme compiles, colors match spec, contrast ratios acceptable | Instructions: Set task 5.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 5.2 Apply HoneyTheme to app
  - File: `lib/main.dart` (modify)
  - Replace current theme with `HoneyTheme.lightTheme`
  - Purpose: Apply honey styling throughout app
  - _Leverage: HoneyTheme from task 5.1_
  - _Requirements: 5.1_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Apply HoneyTheme to MaterialApp | Restrictions: Single line change in theme property | Success: App uses honey colors throughout | Instructions: Set task 5.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 5.3 Update hex grid styling with honey theme
  - Files: `lib/presentation/widgets/hex_grid/hex_cell_widget.dart`, `lib/presentation/widgets/hex_grid/path_painter.dart` (modify)
  - Apply honey colors to cells and path
  - Purpose: Honeycomb visual styling for game grid
  - _Leverage: HoneyTheme colors_
  - _Requirements: 5.2, 5.3_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Update hex grid widgets to use HoneyTheme colors | Restrictions: Maintain existing functionality, only change colors | Success: Grid uses honey colors, path shows gradient effect | Instructions: Set task 5.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 6: Presentation Layer - Screens & Widgets

- [ ] 6.1 Create LevelCellWidget
  - File: `lib/presentation/widgets/level_cell/level_cell_widget.dart`
  - Display level number, star count (0-3), lock icon for locked levels
  - Handle tap with callback, shake animation for locked
  - Purpose: Individual level display in selection grid
  - _Leverage: Styling from HoneyTheme, patterns from HexCellWidget_
  - _Requirements: 1.3, 1.4, 1.5, 2.4, 3.4, 3.5_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Widget Developer | Task: Create LevelCellWidget with level number, stars display, lock state, tap handling | Restrictions: Stateless widget, accept all data via props | Success: Widget displays correctly, tap works, shake animation on locked | Instructions: Set task 6.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 6.2 Create LevelSelectScreen
  - File: `lib/presentation/screens/level_select/level_select_screen.dart`
  - Display scrollable grid of LevelCellWidgets
  - Read from progressProvider and levelRepositoryProvider
  - Navigate to GameScreen with level index on tap
  - Purpose: Main level selection interface
  - _Leverage: LevelCellWidget, providers_
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Screen Developer | Task: Create LevelSelectScreen with GridView of levels, navigation to GameScreen | Restrictions: Use ConsumerWidget, handle loading state | Success: Screen shows all levels, navigation works for unlocked levels | Instructions: Set task 6.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 6.3 Create CompletionOverlay
  - File: `lib/presentation/widgets/completion_overlay/completion_overlay.dart`
  - Display star rating (with animation), completion time
  - Buttons: Next Level, Replay, Level Select
  - Purpose: Post-completion feedback and navigation
  - _Leverage: HoneyTheme styling_
  - _Requirements: 3.4, 4.1, 4.2, 4.3, 4.4, 4.5_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Widget Developer | Task: Create CompletionOverlay with stars, time display, and navigation buttons | Restrictions: Accept callbacks for all actions, animate star appearance | Success: Overlay displays correctly, buttons trigger callbacks, stars animate | Instructions: Set task 6.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 6.4 Update GameScreen with level index and completion overlay
  - File: `lib/presentation/screens/game/game_screen.dart` (modify)
  - Accept level index parameter
  - Replace current completion overlay with new CompletionOverlay
  - Add back button to return to level select
  - Purpose: Integrate level selection with gameplay
  - _Leverage: CompletionOverlay, navigation_
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Modify GameScreen to accept level index, use new CompletionOverlay, add back button | Restrictions: Maintain existing game functionality, update overlay only | Success: Level loads by index, completion shows new overlay, back button works | Instructions: Set task 6.4 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 6.5 Update app navigation to use LevelSelectScreen as home
  - File: `lib/main.dart` (modify)
  - Change home from GameScreen to LevelSelectScreen
  - Set up navigation routes
  - Purpose: Level select as app entry point
  - _Leverage: Navigator, MaterialPageRoute_
  - _Requirements: 1.1_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Update main.dart to use LevelSelectScreen as home, configure navigation | Restrictions: Simple navigation setup, no complex routing needed | Success: App opens to level select, can navigate to game and back | Instructions: Set task 6.5 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 7: Widget Tests

- [ ] 7.1 Write widget tests for LevelCellWidget
  - File: `test/presentation/widgets/level_cell_widget_test.dart`
  - Test: displays level number, stars, lock icon, tap behavior
  - Purpose: Ensure widget renders correctly
  - _Leverage: flutter_test, mockito_
  - _Requirements: Widget Testing strategy_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write widget tests for LevelCellWidget covering all display states | Restrictions: Test visual output and interactions | Success: All widget states tested, tap behavior verified | Instructions: Set task 7.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 7.2 Write widget tests for LevelSelectScreen
  - File: `test/presentation/screens/level_select_screen_test.dart`
  - Test: shows correct number of levels, lock states, navigation
  - Purpose: Ensure screen integrates correctly
  - _Leverage: flutter_test, mock providers_
  - _Requirements: Widget Testing strategy_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write widget tests for LevelSelectScreen with mocked providers | Restrictions: Mock progress and level providers | Success: Screen renders correctly, navigation tested | Instructions: Set task 7.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 7.3 Write widget tests for CompletionOverlay
  - File: `test/presentation/widgets/completion_overlay_test.dart`
  - Test: displays stars and time, button callbacks work
  - Purpose: Ensure completion feedback works
  - _Leverage: flutter_test_
  - _Requirements: Widget Testing strategy_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write widget tests for CompletionOverlay | Restrictions: Test all button callbacks, verify display | Success: All overlay states tested, callbacks verified | Instructions: Set task 7.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

## Phase 8: Integration & Polish

- [ ] 8.1 Add level select header with title and total stars
  - File: `lib/presentation/screens/level_select/level_select_screen.dart` (modify)
  - Add "Honeycomb One Pass" title with honey styling
  - Display total stars collected
  - Purpose: Visual polish and progress summary
  - _Leverage: HoneyTheme_
  - _Requirements: 5.4_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: UI Developer | Task: Add styled header to LevelSelectScreen with title and total stars count | Restrictions: Follow HoneyTheme styling | Success: Header looks polished, total stars displayed | Instructions: Set task 8.1 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 8.2 End-to-end integration test
  - File: `integration_test/level_progression_test.dart`
  - Test: Launch → Level 1 → Complete → Level 2 unlocked → Navigate
  - Test: Replay level → Improve star rating
  - Purpose: Verify complete user flow
  - _Leverage: integration_test package_
  - _Requirements: E2E Testing strategy_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Write E2E test for level progression flow | Restrictions: Test real user journey, no mocks | Success: Complete flow works, progression persists | Instructions: Set task 8.2 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_

- [ ] 8.3 Final review and cleanup
  - Files: All modified files
  - Review code quality, remove unused code
  - Ensure all tests pass
  - Verify pre-commit hooks pass
  - Purpose: Code quality and release readiness
  - _Leverage: dart analyze, flutter test_
  - _Requirements: Code Quality Criteria_
  - _Prompt: Implement the task for spec level-selection-ui, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Senior Developer | Task: Final code review, cleanup, and quality verification | Restrictions: No new features, quality focus only | Success: All tests pass, no lint errors, pre-commit hooks pass | Instructions: Set task 8.3 to in-progress in tasks.md before starting, use log-implementation tool after completion with artifacts, then mark as complete_
