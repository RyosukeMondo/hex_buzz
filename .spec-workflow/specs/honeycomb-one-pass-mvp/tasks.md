# Tasks Document - Honeycomb One Pass MVP

## Phase 1: Project Setup & Core Models

- [x] 1.1. Initialize Flutter project with directory structure
  - Files: `pubspec.yaml`, `lib/main.dart`, directory structure
  - Create Flutter project with web support
  - Set up directory structure per structure.md (lib/core, lib/domain, lib/presentation, lib/debug)
  - Configure pubspec.yaml with dependencies (shelf, args, crypto, riverpod)
  - Purpose: Establish project foundation
  - _Leverage: None (greenfield)_
  - _Requirements: All_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Initialize Flutter project with web support, create directory structure (lib/core, lib/domain, lib/presentation, lib/debug, bin, test), configure pubspec.yaml with dependencies (shelf, args, crypto, flutter_riverpod, logging). Follow structure.md conventions. | Restrictions: Do not add unnecessary dependencies, keep it minimal for MVP | Success: `flutter run -d chrome` launches without errors, directory structure matches structure.md | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 1.2. Create HexCell model
  - File: `lib/domain/models/hex_cell.dart`
  - Implement HexCell class with axial coordinates (q, r)
  - Add checkpoint property, visited flag
  - Implement toPixel() for rendering, neighbors getter
  - Add JSON serialization
  - Purpose: Core data structure for grid cells
  - _Leverage: None_
  - _Requirements: REQ-001, REQ-002_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create HexCell class in lib/domain/models/hex_cell.dart with axial coordinates (q, r), optional checkpoint number, visited flag, toPixel(cellSize) method, neighbors getter returning 6 adjacent coordinates, JSON serialization | Restrictions: No Flutter imports (pure Dart), max 50 lines per function, immutable where possible | Success: Unit tests pass for coordinate conversion, neighbor calculation, JSON round-trip | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 1.3. Create HexEdge model (walls)
  - File: `lib/domain/models/hex_edge.dart`
  - Implement HexEdge class for walls between cells
  - Use canonical ordering for equality
  - Add connects() method, JSON serialization
  - Purpose: Represent blocked passages between cells
  - _Leverage: HexCell_
  - _Requirements: REQ-004_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create HexEdge class in lib/domain/models/hex_edge.dart representing a wall between two adjacent cells. Implement canonical ordering (cell1 < cell2) for consistent equality/hashing, connects() method, JSON serialization | Restrictions: No Flutter imports, ensure HexEdge(A,B) == HexEdge(B,A) | Success: Unit tests pass for equality, canonical ordering, connects() logic | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 1.4. Create Level model
  - File: `lib/domain/models/level.dart`
  - Implement Level class with size, cells map, walls set
  - Add getCell(), startCell, endCell, hasWall(), getPassableNeighbors()
  - Implement computeHash() for level identity
  - Add JSON serialization
  - Purpose: Complete level definition with walls
  - _Leverage: HexCell, HexEdge_
  - _Requirements: REQ-001, REQ-002_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create Level class in lib/domain/models/level.dart with id (hash), size, Map<(int,int), HexCell> cells, Set<HexEdge> walls, checkpointCount. Implement getCell(q,r), startCell/endCell getters, hasWall(), getPassableNeighbors(), computeHash() using SHA-256 of canonical representation, JSON serialization | Restrictions: No Flutter imports, computeHash must be deterministic | Success: Unit tests pass for cell access, wall detection, hash consistency | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 1.5. Create GameMode enum and GameState model
  - Files: `lib/domain/models/game_mode.dart`, `lib/domain/models/game_state.dart`
  - Implement GameMode enum (daily, practice)
  - Implement GameState with level, mode, path, nextCheckpoint, timing
  - Add copyWith for immutable updates
  - Purpose: Track game progress and mode
  - _Leverage: Level, HexCell_
  - _Requirements: REQ-007_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create GameMode enum (daily, practice) in lib/domain/models/game_mode.dart. Create GameState class in lib/domain/models/game_state.dart with Level, GameMode, List<HexCell> path, nextCheckpoint, startTime, endTime. Add isStarted, isComplete, elapsedTime, canSubmitToLeaderboard getters, copyWith() method | Restrictions: No Flutter imports, immutable state pattern | Success: Unit tests pass for state transitions, copyWith works correctly | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

## Phase 2: Core Services (Domain Logic)

- [x] 2.1. Create PathValidator service
  - File: `lib/domain/services/path_validator.dart`
  - Implement isAdjacent(), isPassable() (wall check), isValidMove()
  - Implement checkWinCondition()
  - Purpose: Validate moves and detect win
  - _Leverage: Level, HexCell, HexEdge, GameState_
  - _Requirements: REQ-004, REQ-007_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create PathValidator in lib/domain/services/path_validator.dart with pure functions: isAdjacent(HexCell a, HexCell b), isPassable(Level, HexCell from, HexCell to) checking walls, isValidMove(GameState, HexCell target) checking adjacency + walls + visited + checkpoint order, checkWinCondition(GameState) checking all cells visited + correct checkpoint order | Restrictions: No Flutter imports, pure functions only, no side effects | Success: Unit tests cover all validation cases including wall blocking | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 2.2. Create GameEngine service
  - File: `lib/domain/services/game_engine.dart`
  - Implement state getter, tryMove(), undo(), reset()
  - Use PathValidator for move validation
  - Track timing on first move and completion
  - Purpose: Core game state machine
  - _Leverage: PathValidator, GameState, Level_
  - _Requirements: REQ-003, REQ-004, REQ-005, REQ-006, REQ-007_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create GameEngine class in lib/domain/services/game_engine.dart with GameState state getter, tryMove(HexCell) returning bool (uses PathValidator), undo() removing last path segment, reset() clearing path. Start timer on first move, record endTime on win | Restrictions: No Flutter imports, use PathValidator for all validation, emit state changes | Success: Unit tests pass for move/undo/reset, timing is accurate | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 2.3. Create LevelValidator service
  - File: `lib/domain/services/level_validator.dart`
  - Implement validate() checking solvability
  - Implement findSolution() using DFS/backtracking
  - Return structured ValidationResult
  - Purpose: Verify levels are solvable (for CLI)
  - _Leverage: PathValidator, Level_
  - _Requirements: REQ-009_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer specializing in algorithms | Task: Create LevelValidator in lib/domain/services/level_validator.dart with validate(Level) returning ValidationResult (isSolvable, solutionPath?, error?), findSolution(Level) using DFS backtracking to find Hamiltonian path through checkpoints in order | Restrictions: No Flutter imports, algorithm must handle walls correctly | Success: Unit tests pass for solvable/unsolvable levels, solution is valid when found | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

## Phase 3: Core Infrastructure

- [x] 3.1. Create structured logging
  - File: `lib/core/logging/logger.dart`
  - Implement JSON structured logger
  - Include timestamp, level, component, event, context
  - Support stdout and optional file output
  - Purpose: AI agent can analyze logs
  - _Leverage: None_
  - _Requirements: REQ-010_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create Logger class in lib/core/logging/logger.dart with JSON output format containing timestamp (ISO8601), level (debug/info/warn/error), component (string), event (string), context (Map). Support log levels, stdout output. Create global logger instance | Restrictions: No Flutter imports, JSON format for AI parsing | Success: Logs are valid JSON, can filter by level, context is included | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [x] 3.2. Create hardcoded test level
  - File: `lib/domain/data/test_level.dart`
  - Create a simple 4x4 solvable level with walls
  - Include 3 checkpoints
  - Verify solvability with LevelValidator
  - Purpose: Test level for development
  - _Leverage: Level, HexCell, HexEdge, LevelValidator_
  - _Requirements: REQ-001, REQ-002_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Game Designer/Developer | Task: Create hardcoded test level in lib/domain/data/test_level.dart - a 4x4 hexagonal grid with 3 checkpoints and strategic walls that create exactly one solution path. Export as getTestLevel() function. Verify with LevelValidator | Restrictions: Must be solvable, not too easy (needs some walls) | Success: LevelValidator confirms solvability, solution path visits all cells | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

## Phase 4: Debug Layer (AI Agent Interface)

- [ ] 4.1. Create CLI runner framework
  - Files: `lib/debug/cli/cli_runner.dart`, `bin/cli.dart`
  - Set up args package for command parsing
  - Create CLI entry point
  - Purpose: CLI framework for AI agent commands
  - _Leverage: args package_
  - _Requirements: REQ-009_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create CLI framework in lib/debug/cli/cli_runner.dart using args package. Set up bin/cli.dart as entry point. Support --help, subcommands structure. Output JSON for AI parsing | Restrictions: JSON output format, clear error messages | Success: `dart run bin/cli.dart --help` shows usage, subcommand structure works | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 4.2. Implement CLI validate command
  - File: `lib/debug/cli/commands/validate_command.dart`
  - Add validate command accepting level JSON
  - Output validation result as JSON
  - Include solution path if solvable
  - Purpose: AI agent can validate levels
  - _Leverage: LevelValidator, CLI runner_
  - _Requirements: REQ-009_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create validate command in lib/debug/cli/commands/validate_command.dart. Accept --level <json_string> or --file <path>. Use LevelValidator to check solvability. Output JSON: {valid: bool, solvable: bool, solution?: [...], error?: string} | Restrictions: JSON output only, handle malformed input gracefully | Success: CLI validates test level correctly, outputs structured JSON | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 4.3. Create REST API server
  - File: `lib/debug/api/server.dart`
  - Set up shelf HTTP server
  - Configure CORS for local development
  - Add JSON request/response handling
  - Purpose: HTTP server for AI agent
  - _Leverage: shelf package_
  - _Requirements: REQ-008_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create HTTP server in lib/debug/api/server.dart using shelf package. Configure CORS for localhost, JSON content type. Create startServer(int port, GameEngine engine) function. Add graceful shutdown | Restrictions: Localhost only for MVP, JSON responses | Success: Server starts on specified port, responds to requests | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 4.4. Implement REST API game endpoints
  - File: `lib/debug/api/routes/game_routes.dart`
  - GET /api/game/state - returns GameStateResponse
  - POST /api/game/move - executes move
  - POST /api/game/reset - resets level
  - Purpose: AI agent can play game via API
  - _Leverage: GameEngine, shelf, API server_
  - _Requirements: REQ-008_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create game routes in lib/debug/api/routes/game_routes.dart. Implement GET /api/game/state returning full game state JSON, POST /api/game/move accepting {q, r} and returning success/error + new state, POST /api/game/reset returning fresh state. Use GameEngine | Restrictions: Return proper HTTP status codes (200, 400), structured error responses | Success: curl commands successfully interact with game state | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 4.5. Implement REST API level endpoints
  - File: `lib/debug/api/routes/level_routes.dart`
  - POST /api/level/validate - validates level JSON
  - Purpose: AI agent can validate levels via API
  - _Leverage: LevelValidator, shelf, API server_
  - _Requirements: REQ-008, REQ-009_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Dart Developer | Task: Create level routes in lib/debug/api/routes/level_routes.dart. Implement POST /api/level/validate accepting level JSON, returning validation result with solvability and optional solution | Restrictions: Proper error handling for malformed JSON | Success: API validates test level correctly | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

## Phase 5: Presentation Layer (UI)

- [ ] 5.1. Create hex grid coordinate utilities
  - File: `lib/presentation/utils/hex_utils.dart`
  - Implement pixel-to-axial coordinate conversion
  - Implement axial-to-pixel conversion
  - Calculate cell vertices for rendering
  - Purpose: Coordinate math for rendering and hit testing
  - _Leverage: HexCell_
  - _Requirements: REQ-001_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer with geometry knowledge | Task: Create hex utilities in lib/presentation/utils/hex_utils.dart. Implement pixelToAxial(Offset, cellSize), axialToPixel(q, r, cellSize), getHexVertices(center, size) returning 6 points for flat-top hexagon | Restrictions: Use pointy-top or flat-top consistently, accurate math | Success: Coordinates convert correctly in both directions | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 5.2. Create HexCellWidget
  - File: `lib/presentation/widgets/hex_grid/hex_cell_widget.dart`
  - Render single hexagonal cell using CustomPaint
  - Show checkpoint number if present
  - Indicate visited state with color
  - Purpose: Individual cell rendering
  - _Leverage: HexCell, hex_utils_
  - _Requirements: REQ-001, REQ-002_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Create HexCellWidget in lib/presentation/widgets/hex_grid/hex_cell_widget.dart using CustomPainter. Draw hexagon shape, fill based on visited state (gray=unvisited, colored=visited), show checkpoint number centered if present. Highlight start (green border) and end (red border) checkpoints | Restrictions: Use CustomPaint for performance, no external packages | Success: Cells render correctly with all visual states | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 5.3. Create WallPainter
  - File: `lib/presentation/widgets/hex_grid/wall_painter.dart`
  - Render walls as thick lines on cell edges
  - Calculate wall positions from HexEdge data
  - Purpose: Visualize blocked passages
  - _Leverage: HexEdge, hex_utils_
  - _Requirements: REQ-001_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Create WallPainter in lib/presentation/widgets/hex_grid/wall_painter.dart as CustomPainter. Given Set<HexEdge> walls and cell size, draw thick dark lines on shared edges between cells. Calculate edge midpoints from cell centers | Restrictions: Walls must align exactly with hex edges | Success: Walls render on correct edges, visually distinct | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 5.4. Create PathPainter
  - File: `lib/presentation/widgets/hex_grid/path_painter.dart`
  - Draw path as connected line through cell centers
  - Implement color gradient based on path length
  - Purpose: Visualize player's drawn path
  - _Leverage: hex_utils, GameState_
  - _Requirements: REQ-003_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Create PathPainter in lib/presentation/widgets/hex_grid/path_painter.dart as CustomPainter. Draw path as thick line connecting cell centers. Implement gradient from blue to purple to red based on path progress (0% to 100% of total cells) | Restrictions: Smooth line rendering, gradient must be visible | Success: Path renders with color gradient, updates smoothly | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 5.5. Create HexGridWidget
  - File: `lib/presentation/widgets/hex_grid/hex_grid_widget.dart`
  - Compose cells, walls, path painters
  - Handle touch/mouse drag input
  - Convert pointer position to cell coordinates
  - Emit cell interactions to parent
  - Purpose: Complete interactive grid
  - _Leverage: HexCellWidget, WallPainter, PathPainter, hex_utils_
  - _Requirements: REQ-001, REQ-002, REQ-003_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Create HexGridWidget in lib/presentation/widgets/hex_grid/hex_grid_widget.dart. Use GestureDetector for pan gestures. Render all cells, walls overlay, path overlay. On drag, convert position to cell coords, call onCellEntered callback. Handle drag start/end | Restrictions: Efficient rendering (RepaintBoundary), responsive to all screen sizes | Success: Grid renders correctly, drag interactions detected accurately | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 5.6. Create GameScreen with state management
  - File: `lib/presentation/screens/game/game_screen.dart`
  - Integrate HexGridWidget with GameEngine
  - Add reset button
  - Show completion state
  - Use Riverpod for state management
  - Purpose: Main playable screen
  - _Leverage: HexGridWidget, GameEngine, Riverpod_
  - _Requirements: REQ-003, REQ-006, REQ-007_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Create GameScreen in lib/presentation/screens/game/game_screen.dart. Use Riverpod provider for GameEngine. Connect HexGridWidget interactions to GameEngine.tryMove(). Add reset button calling GameEngine.reset(). Show "Complete!" overlay on win with elapsed time | Restrictions: Use Riverpod for state, clean separation of concerns | Success: Full gameplay works - draw path, undo by backtracking, reset, win detection | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

## Phase 6: Integration & Testing

- [ ] 6.1. Create unit tests for models
  - Files: `test/domain/models/*_test.dart`
  - Test HexCell, HexEdge, Level, GameState
  - Test hash consistency for Level
  - Purpose: Ensure model correctness
  - _Leverage: flutter_test_
  - _Requirements: All model requirements_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create unit tests in test/domain/models/ for HexCell (neighbors, toPixel), HexEdge (canonical ordering, equality), Level (hasWall, getPassableNeighbors, computeHash determinism), GameState (copyWith, computed properties) | Restrictions: 80%+ coverage, test edge cases | Success: All tests pass, coverage meets target | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 6.2. Create unit tests for services
  - Files: `test/domain/services/*_test.dart`
  - Test PathValidator, GameEngine, LevelValidator
  - Test wall blocking scenarios
  - Purpose: Ensure game logic correctness
  - _Leverage: flutter_test, test level_
  - _Requirements: REQ-004, REQ-007, REQ-009_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create unit tests in test/domain/services/ for PathValidator (adjacency, wall blocking, checkpoint order), GameEngine (move, undo, reset, win detection), LevelValidator (solvable levels, unsolvable levels, solution correctness) | Restrictions: 80%+ coverage, test all validation rules | Success: All tests pass, all game rules verified | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 6.3. Create API integration tests
  - File: `test/debug/api/server_test.dart`
  - Test all REST endpoints
  - Test error responses
  - Purpose: Ensure API works for AI agents
  - _Leverage: http package, test server_
  - _Requirements: REQ-008_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create integration tests in test/debug/api/server_test.dart. Start test server, test GET /api/game/state, POST /api/game/move (valid and invalid), POST /api/game/reset, POST /api/level/validate. Verify JSON responses | Restrictions: Clean up server after tests, test error cases | Success: All API endpoints work correctly, error responses are structured | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 6.4. Wire up main.dart and test full flow
  - File: `lib/main.dart`
  - Initialize app with test level
  - Start debug API server in debug mode
  - Launch GameScreen
  - Purpose: Complete working MVP
  - _Leverage: All components_
  - _Requirements: All_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Flutter Developer | Task: Update lib/main.dart to initialize Riverpod, load test level, optionally start debug API server (port 8080) when in debug mode, launch MaterialApp with GameScreen. Add command line flag --api to enable API server | Restrictions: API server only in debug mode, clean startup | Success: `flutter run -d chrome` shows playable game, API responds to curl | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_

- [ ] 6.5. Setup pre-commit hooks
  - Files: `scripts/pre_commit.dart`, `.githooks/pre-commit`
  - Implement file size check (500 lines)
  - Implement function size check (50 lines)
  - Run dart format and analyze
  - Purpose: Enforce code quality
  - _Leverage: dart analyze_
  - _Requirements: tech.md pre-commit requirements_
  - _Prompt: Implement the task for spec honeycomb-one-pass-mvp, first run spec-workflow-guide to get the workflow guide then implement the task: Role: DevOps Engineer | Task: Create pre-commit hook in scripts/pre_commit.dart checking: file size ≤500 LOC (excluding comments/blanks), function size ≤50 LOC. Create .githooks/pre-commit shell script running dart format --set-exit-if-changed, dart analyze --fatal-infos, dart run scripts/pre_commit.dart, flutter test | Restrictions: Must fail fast on violations, clear error messages | Success: Commits blocked when rules violated, passes for valid code | After completing: Mark task [-] as in-progress before starting, use log-implementation tool to record what was created, then mark [x] complete_
