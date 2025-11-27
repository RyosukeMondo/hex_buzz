# Project Structure

## Directory Organization

```
honeycomb-one-pass/
├── lib/                          # Main application source
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App configuration and routing
│   │
│   ├── core/                     # Core utilities and shared code
│   │   ├── logging/              # Structured logging (JSON format)
│   │   ├── constants/            # App-wide constants
│   │   └── utils/                # Common utility functions
│   │
│   ├── domain/                   # Business logic (framework-independent)
│   │   ├── models/               # Data models (HexCell, Level, GameState)
│   │   ├── services/             # Game logic services
│   │   │   ├── level_generator.dart    # Level generation algorithm
│   │   │   ├── level_validator.dart    # Solvability validation
│   │   │   ├── path_validator.dart     # Path/move validation
│   │   │   └── game_engine.dart        # Core game state machine
│   │   └── repositories/         # Data access interfaces
│   │
│   ├── data/                     # Data layer implementation
│   │   ├── local/                # Local storage (levels, progress)
│   │   └── remote/               # Future: leaderboard API
│   │
│   ├── presentation/             # UI layer
│   │   ├── screens/              # Full-page screens
│   │   │   ├── game/             # Game play screen
│   │   │   ├── level_select/     # Level selection screen
│   │   │   └── settings/         # Settings screen
│   │   ├── widgets/              # Reusable UI components
│   │   │   ├── hex_grid/         # Hexagonal grid rendering
│   │   │   ├── path_painter/     # Path visualization
│   │   │   └── effects/          # Visual effects (celebrations)
│   │   └── providers/            # State management (Riverpod)
│   │
│   └── debug/                    # AI Agent debug layer
│       ├── api/                  # REST API endpoints
│       │   ├── server.dart       # HTTP server setup
│       │   ├── game_routes.dart  # Game state endpoints
│       │   └── level_routes.dart # Level generation endpoints
│       └── cli/                  # CLI commands
│           ├── cli_runner.dart   # CLI entry point
│           ├── generate_cmd.dart # Level generation command
│           └── validate_cmd.dart # Level validation command
│
├── bin/                          # Executable entry points
│   ├── main.dart                 # Flutter app entry
│   └── cli.dart                  # CLI tool entry
│
├── test/                         # Test files (mirrors lib/ structure)
│   ├── domain/                   # Unit tests for business logic
│   ├── data/                     # Data layer tests
│   ├── presentation/             # Widget tests
│   └── debug/                    # API/CLI tests
│
├── integration_test/             # End-to-end tests
│
├── assets/                       # Static assets
│   ├── sounds/                   # Sound effects
│   └── fonts/                    # Custom fonts (if any)
│
├── scripts/                      # Development scripts
│   ├── pre_commit.dart           # Pre-commit validation
│   └── code_metrics.dart         # Code metrics checker
│
└── docs/                         # Documentation (minimal)
    └── api/                      # Generated API docs
```

## Naming Conventions

### Files
- **Dart files**: `snake_case.dart` (e.g., `level_generator.dart`, `hex_grid.dart`)
- **Test files**: `[filename]_test.dart` (e.g., `level_generator_test.dart`)
- **Widgets**: `snake_case.dart` matching class name (e.g., `hex_cell_widget.dart` for `HexCellWidget`)

### Code
- **Classes/Types**: `PascalCase` (e.g., `HexCell`, `GameState`, `LevelGenerator`)
- **Functions/Methods**: `camelCase` (e.g., `generateLevel`, `validatePath`)
- **Constants**: `camelCase` for local, `SCREAMING_CASE` for global (e.g., `maxGridSize`, `MAX_CHECKPOINTS`)
- **Variables**: `camelCase` (e.g., `currentLevel`, `pathSegments`)
- **Private members**: `_camelCase` (e.g., `_internalState`)

## Import Patterns

### Import Order
1. Dart SDK imports (`dart:`)
2. Flutter imports (`package:flutter/`)
3. External packages (`package:`)
4. Internal packages (`package:honeycomb_one_pass/`)
5. Relative imports (`./`, `../`)

### Module Organization
```dart
// Preferred: Absolute imports for cross-module references
import 'package:honeycomb_one_pass/domain/models/hex_cell.dart';

// Acceptable: Relative imports within same feature
import '../widgets/hex_cell_widget.dart';
```

## Code Structure Patterns

### Module/Class Organization
```dart
// 1. Imports (ordered as above)
// 2. Part directives (if using)
// 3. Constants
// 4. Type definitions / Enums
// 5. Main class/function
// 6. Helper classes (private)
```

### Function Organization
```dart
// 1. Guard clauses / Input validation (fail fast)
// 2. Core logic
// 3. Return statement
```

### File Organization Principles
- One primary class per file (+ related private helpers)
- File name matches primary class name in snake_case
- Keep related code together, but split when approaching 500 lines

## Code Organization Principles

1. **Single Responsibility**: Each file has one clear purpose
2. **Modularity**: Domain logic is completely independent of UI
3. **Testability**: All business logic testable without Flutter
4. **Consistency**: Follow established patterns in codebase

## Module Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                      presentation/                          │
│  (Depends on: domain, core)                                 │
│  - Can import: domain/models, domain/services, core/*       │
│  - Cannot import: data/, debug/                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        domain/                               │
│  (Depends on: core only)                                    │
│  - Framework-independent business logic                      │
│  - No Flutter imports allowed                                │
│  - Testable with pure Dart                                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         core/                                │
│  (No internal dependencies)                                  │
│  - Logging, constants, pure utilities                        │
│  - No Flutter imports (except for core Flutter utilities)    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        debug/                                │
│  (Depends on: domain, core)                                 │
│  - REST API and CLI for AI agent interaction                 │
│  - Isolated from presentation layer                          │
│  - Can be excluded from production builds                    │
└─────────────────────────────────────────────────────────────┘
```

**Dependency Rules**:
- `domain/` → imports only `core/`
- `presentation/` → imports `domain/` and `core/`
- `data/` → imports `domain/` (for interfaces) and `core/`
- `debug/` → imports `domain/` and `core/`
- **Never**: `domain/` imports from `presentation/`, `data/`, or `debug/`

## Code Size Guidelines

| Metric | Limit | Rationale |
|--------|-------|-----------|
| **File size** | Max 500 lines (excluding comments/blanks) | Enforced by pre-commit |
| **Function size** | Max 50 lines (excluding comments/blanks) | Enforced by pre-commit |
| **Cyclomatic complexity** | Max 10 per function | Enforced by dart_code_metrics |
| **Nesting depth** | Max 4 levels | Readability |
| **Parameters** | Max 5 per function | Consider object parameter if more |

## Debug/API Structure

### REST API Endpoints
```
GET  /api/game/state           → Current game state JSON
POST /api/game/move            → Execute move, returns new state
POST /api/game/reset           → Reset current level
GET  /api/level/list           → List available levels
GET  /api/level/:id            → Get level definition
POST /api/level/generate       → Generate new level
POST /api/level/validate       → Validate level solvability
```

### CLI Commands
```
$ honeycomb-cli generate --size 6 --checkpoints 4    # Generate level
$ honeycomb-cli validate --file level.json           # Validate level
$ honeycomb-cli solve --file level.json              # Find solution
$ honeycomb-cli test --all                           # Run all validations
```

## Documentation Standards
- Public APIs: dartdoc comments required
- Complex algorithms: Inline comments explaining approach
- No README files per module (keep it simple - KISS)
- API documentation auto-generated via dartdoc
