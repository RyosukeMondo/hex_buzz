# Technology Stack

## Project Type
Cross-platform mobile/web/desktop puzzle game with AI Agent-first development architecture.

## Core Technologies

### Primary Language(s)
- **Language**: Dart (latest stable)
- **Runtime**: Flutter SDK
- **Language-specific tools**: pub (package manager), dart analyze, dart format

### Key Dependencies/Libraries
- **Flutter**: Cross-platform UI framework (Web, Android, iOS, Linux, Windows)
- **flame** (optional): 2D game engine for Flutter (for advanced visual effects)
- **provider/riverpod**: State management
- **http/dio**: REST API client for debug endpoints
- **logger**: Structured logging library
- **shelf**: Dart HTTP server for REST API debug endpoints

### Application Architecture
- **Pattern**: Clean Architecture with feature-first organization
- **State Management**: Reactive state with provider/riverpod
- **Game Logic**: Separate from UI, fully testable via CLI/API
- **Debug Layer**: REST API server embedded for AI agent interaction

### Data Storage
- **Primary storage**: Local device storage (shared_preferences, hive)
- **Cloud storage**: Firebase/Supabase for leaderboard data (future)
- **Caching**: In-memory game state
- **Data formats**: JSON for API responses and level definitions

### External Integrations
- **APIs**: Future leaderboard cloud service
- **Protocols**: HTTP/REST for debug API, WebSocket for real-time updates (future)
- **Authentication**: Anonymous for MVP, optional account linking (future)

### Monitoring & Dashboard Technologies
- **Debug Dashboard**: Flutter Web or CLI-based
- **Real-time Communication**: REST API polling, WebSocket (future)
- **Visualization Libraries**: Flutter Canvas for game rendering
- **State Management**: Game state as single source of truth

## Development Environment

### Build & Development Tools
- **Build System**: Flutter CLI (`flutter build`, `flutter run`)
- **Package Management**: pub (pubspec.yaml)
- **Development workflow**: Hot reload for UI, CLI for game logic testing

### Code Quality Tools
- **Static Analysis**: dart analyze, flutter analyze with strict rules
- **Formatting**: dart format (enforced)
- **Testing Framework**:
  - flutter_test for unit/widget tests
  - integration_test for E2E
  - CLI test runner for headless game logic validation
- **Documentation**: dartdoc for API documentation

### Development Principles
The following principles guide all development decisions. **When tradeoffs occur, prioritize KISS above all others.**

| Principle | Description | Priority |
|-----------|-------------|----------|
| **KISS** | Keep It Simple, Stupid - Choose the simplest solution that works | **Highest** |
| **SOLID** | Single responsibility, Open-closed, Liskov substitution, Interface segregation, Dependency inversion | High |
| **SLAP** | Single Level of Abstraction Principle - Each function operates at one abstraction level | High |
| **DRY** | Don't Repeat Yourself - Extract common logic, but not at the cost of simplicity | Medium |
| **SSOT** | Single Source of Truth - One authoritative source for each piece of data | Medium |

**Tradeoff Resolution**:
- If DRY creates complex abstractions → prefer KISS, accept some duplication
- If SOLID adds unnecessary layers → prefer KISS, simplify architecture
- If SLAP requires many tiny functions → prefer KISS, balance readability
- Always ask: "Is this the simplest solution that meets requirements?"

### Pre-commit Verification
Mandatory pre-commit hooks enforce the following limits (excluding comments and blank lines):

| Metric | Limit | Enforcement |
|--------|-------|-------------|
| **File size** | Max 500 lines of code | Pre-commit hook rejects commits exceeding limit |
| **Function size** | Max 50 lines of code | Pre-commit hook rejects commits exceeding limit |
| **Cyclomatic complexity** | Max 10 per function | Static analysis with dart_code_metrics |

**Pre-commit checks include**:
1. `dart format --set-exit-if-changed` - Code formatting
2. `dart analyze --fatal-infos` - Static analysis
3. File/function size validation script
4. Cyclomatic complexity check via dart_code_metrics
5. `flutter test` - Unit tests must pass

### Version Control & Collaboration
- **VCS**: Git
- **Branching Strategy**: GitHub Flow (main + feature branches)
- **Code Review Process**: PR-based with AI agent pre-review

### AI Agent Development Support
- **CLI Interface**: Dedicated CLI commands for:
  - Level generation and validation
  - Game state queries
  - Algorithm testing
  - Automated gameplay simulation
- **REST API**: Debug endpoints for:
  - GET /api/game/state - Current game state
  - POST /api/game/move - Execute move
  - GET /api/level/validate - Validate level solvability
  - GET /api/level/generate - Generate new level
- **Structured Logging**: JSON format with timestamp, level, component, event, context

## Deployment & Distribution
- **Target Platform(s)**: Web (primary for testing), Android, iOS, Linux, Windows
- **Distribution Method**:
  - Web: Static hosting (Vercel, Firebase Hosting)
  - Mobile: App stores (Google Play, App Store)
  - Desktop: Direct download / package managers
- **Installation Requirements**: None for web; standard mobile/desktop requirements
- **Update Mechanism**: App store updates for mobile; auto-update for web

## Technical Requirements & Constraints

### Performance Requirements
- 60 FPS minimum during gameplay
- < 100ms response for move validation
- < 2 seconds initial load time
- Memory usage < 100MB on mobile

### Compatibility Requirements
- **Platform Support**: Android 5.0+, iOS 12+, Modern browsers (Chrome, Firefox, Safari, Edge), Windows 10+, Linux (GTK)
- **Dependency Versions**: Flutter 3.x stable channel
- **Standards Compliance**: Material Design 3 guidelines

### Security & Compliance
- **Security Requirements**: No sensitive data handling in MVP
- **Compliance Standards**: COPPA-friendly (no data collection from children)
- **Threat Model**: Minimal - single-player offline game

### Scalability & Reliability
- **Expected Load**: Single user per instance (client-side game)
- **Availability Requirements**: Offline-capable gameplay
- **Growth Projections**: Leaderboard backend scaling (future)

## Technical Decisions & Rationale

### Decision Log
1. **Flutter over native**: Cross-platform from single codebase; excellent performance for 2D games
2. **Dart for game logic**: Same language for UI and logic; easier AI agent integration
3. **REST API for debugging**: Standard protocol AI agents understand; easy to test with curl/httpie
4. **Clean Architecture**: Testable game logic independent of UI; supports CLI-first development

## Known Limitations

- **Web performance**: Slightly lower than native for complex animations (acceptable for puzzle game)
- **Desktop distribution**: Less mature than mobile app stores
- **Hot reload limitations**: Game state may need manual reset during development
