# Requirements Document: Level Selection UI & Game Polish

## Introduction

This spec covers the comprehensive level selection system, progression mechanics, star rating system, and overall UI/UX polish for Honeycomb One Pass. The goal is to transform the current functional prototype into an engaging, visually appealing game with honey/bee theming that provides satisfying progression feedback to players.

## Alignment with Product Vision

This feature directly supports the product goals outlined in product.md:
- **Progressive Difficulty**: Level selection screen enables structured progression through difficulty tiers
- **Celebration Animations**: Star system and completion feedback provide satisfying moments
- **Universal Accessibility**: Visual/icon-based UI works across all languages (honey, bee icons are universally recognizable)
- **User Retention**: Progression mechanics and star collection drive repeat play
- **AI Agent-First Development**: CLI/API for progress management before UI implementation

## Architectural Principles & Criteria

This implementation MUST adhere to the following principles defined in tech.md and structure.md:

### Development Principles (Priority Order)

| Principle | Application in This Feature | Priority |
|-----------|----------------------------|----------|
| **KISS** | Simple star calculation (time thresholds), straightforward unlock logic (complete N → unlock N+1), minimal abstraction layers | **Highest** |
| **SOLID** | Single Responsibility: separate ProgressRepository (persistence), StarCalculator (logic), ProgressNotifier (state) | High |
| **SLAP** | Each function at one abstraction level - UI doesn't know persistence details, services don't know widget details | High |
| **DRY** | Reuse existing LevelRepository, extend GameState model rather than duplicate | Medium |
| **SSOT** | ProgressState as single source of truth for unlock status and star counts | Medium |

### Module Boundaries (from structure.md)

```
┌─────────────────────────────────────────────────────────────┐
│                      presentation/                          │
│  - LevelSelectScreen, CompletionOverlay widgets            │
│  - ProgressNotifier (Riverpod state management)            │
│  - Theme configuration (HoneyTheme)                        │
│  - Can import: domain/models, domain/services, core/*      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        domain/                               │
│  - ProgressState model (unlocked levels, star counts)      │
│  - StarCalculator service (time → stars logic)             │
│  - ProgressRepository interface (abstract)                  │
│  - No Flutter imports - pure Dart, fully testable          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         data/                                │
│  - LocalProgressRepository (shared_preferences impl)        │
│  - Progress data serialization/deserialization              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        debug/                                │
│  - CLI commands: progress get, progress set, progress reset │
│  - REST API: GET/POST /api/progress                         │
│  - Enable AI agent to test progression without UI           │
└─────────────────────────────────────────────────────────────┘
```

### AI Agent-First Development Order

Per product.md, implementation MUST follow this order:
1. **First**: CLI commands for progress management (`progress get`, `progress set`, `progress reset`)
2. **Second**: REST API endpoints (`GET /api/progress`, `POST /api/progress`)
3. **Third**: Domain models and services (ProgressState, StarCalculator)
4. **Fourth**: UI components (LevelSelectScreen, CompletionOverlay, theme)

### Code Quality Criteria (from tech.md)

| Metric | Limit | Enforcement |
|--------|-------|-------------|
| **File size** | Max 500 lines | Pre-commit hook |
| **Function size** | Max 50 lines | Pre-commit hook |
| **Cyclomatic complexity** | Max 10 per function | dart_code_metrics |

### Testability Requirements

- All domain logic (StarCalculator, unlock logic) MUST be testable without Flutter
- CLI commands MUST be testable via unit tests
- Progress persistence MUST be mockable for widget tests
- Star calculation: provide test cases for boundary conditions (9.99s, 10.00s, 10.01s, etc.)

## Requirements

### Requirement 1: Level Selection Screen

**User Story:** As a player, I want to see all available levels organized in a grid, so that I can choose which level to play and track my progress.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL display the level selection screen as the home screen
2. WHEN the level selection screen loads THEN the system SHALL display levels in a scrollable honeycomb-style grid pattern
3. WHEN displaying each level THEN the system SHALL show:
   - Level number (1, 2, 3...)
   - Lock/unlock status (locked levels show a lock icon)
   - Star rating (0-3 stars based on best completion time)
   - Honeycomb cell visual styling
4. WHEN a player taps on an unlocked level THEN the system SHALL navigate to the game screen with that level loaded
5. WHEN a player taps on a locked level THEN the system SHALL display a subtle feedback (shake animation) and NOT navigate

### Requirement 2: Level Progression & Unlocking

**User Story:** As a player, I want levels to unlock progressively as I complete previous levels, so that I feel a sense of accomplishment and have a clear goal.

#### Acceptance Criteria

1. WHEN the app first launches THEN the system SHALL have only Level 1 unlocked
2. WHEN a player completes a level for the first time THEN the system SHALL unlock the next level
3. WHEN a player completes a previously completed level THEN the system SHALL NOT change unlock status of other levels
4. WHEN displaying locked levels THEN the system SHALL show them visually distinct (grayed out with lock icon)
5. IF user progress data exists THEN the system SHALL restore unlock status on app launch
6. WHEN saving progress THEN the system SHALL persist to local storage (survive app restart)

### Requirement 3: Star Rating System

**User Story:** As a player, I want to earn stars based on my completion time, so that I have a reason to replay levels and improve my performance.

#### Acceptance Criteria

1. WHEN a player completes a level THEN the system SHALL award stars based on completion time:
   - 1 star: Complete within 60 seconds
   - 2 stars: Complete within 30 seconds
   - 3 stars: Complete within 10 seconds
2. WHEN a player improves their time THEN the system SHALL update the star count to the higher value
3. WHEN a player gets a worse time THEN the system SHALL keep the previous best star count
4. WHEN displaying level completion THEN the system SHALL show star animation for earned stars
5. WHEN returning to level select THEN the system SHALL display the best star count for each level
6. WHEN tracking time THEN the system SHALL start the timer when the player makes their first move (not on level load)

### Requirement 4: Game Screen Navigation & Feedback

**User Story:** As a player, I want clear navigation between level select and gameplay, with satisfying completion feedback.

#### Acceptance Criteria

1. WHEN playing a level THEN the system SHALL display a back button to return to level select
2. WHEN a player completes a level THEN the system SHALL display a completion overlay showing:
   - Star rating earned (with animation)
   - Completion time
   - "Next Level" button (if next level exists)
   - "Replay" button
   - "Level Select" button
3. WHEN the player presses "Next Level" THEN the system SHALL load the next level immediately
4. WHEN the player presses "Replay" THEN the system SHALL reset the current level
5. WHEN the player presses "Level Select" THEN the system SHALL navigate back to level selection

### Requirement 5: Honey/Bee Theme Visual Design

**User Story:** As a player, I want an attractive honey and bee themed game, so that the experience feels polished and enjoyable.

#### Acceptance Criteria

1. WHEN displaying the app THEN the system SHALL use a warm honey color palette:
   - Primary: Amber/honey gold (#FFC107, #FFB300)
   - Secondary: Deep honey/orange (#FF8F00, #FF6F00)
   - Background: Warm cream (#FFF8E1, #FFECB3)
   - Accents: Brown (#795548) for contrast
2. WHEN displaying hexagonal cells THEN the system SHALL style them as honeycomb cells:
   - Unvisited: Light honey yellow with subtle cell border
   - Visited: Darker amber/golden fill
   - Checkpoint: Distinct marking (bee icon or number badge)
3. WHEN displaying the path THEN the system SHALL use a honey-drip gradient effect (light to dark amber)
4. WHEN displaying the level select screen THEN the system SHALL include:
   - Honeycomb background pattern
   - Decorative bee character/mascot (simple, cute design)
   - "Honeycomb One Pass" title with honey drip effect
5. WHEN displaying UI elements (buttons, cards) THEN the system SHALL use rounded honey-drop shapes and amber accents
6. WHEN a player earns stars THEN the system SHALL display golden/amber star icons

### Requirement 6: Debug/CLI Interface (AI Agent Support)

**User Story:** As an AI agent developer, I want CLI and API access to progress data, so that I can test progression logic without UI interaction.

#### Acceptance Criteria

1. WHEN running `honeycomb-cli progress get` THEN the system SHALL output JSON with current progress state
2. WHEN running `honeycomb-cli progress set --level N --stars S` THEN the system SHALL update progress for level N
3. WHEN running `honeycomb-cli progress reset` THEN the system SHALL clear all progress data
4. WHEN calling `GET /api/progress` THEN the system SHALL return current progress as JSON
5. WHEN calling `POST /api/progress` with level completion data THEN the system SHALL update progress
6. WHEN progress changes via CLI/API THEN the system SHALL persist changes to local storage

### Requirement 7: Sound & Haptic Feedback (Optional Enhancement)

**User Story:** As a player, I want audio and haptic feedback for actions, so that the game feels responsive and satisfying.

#### Acceptance Criteria

1. WHEN a player makes a valid move THEN the system SHALL play a soft "pop" sound (if sounds enabled)
2. WHEN a player completes a level THEN the system SHALL play a celebratory chime
3. WHEN a player earns a star THEN the system SHALL play a star-collection sound
4. WHEN sounds are disabled in settings THEN the system SHALL NOT play any sounds
5. WHEN a player taps a locked level THEN the system SHALL provide haptic feedback (vibration) on supported devices

## Non-Functional Requirements

### Code Architecture and Modularity
- **Single Responsibility Principle**: Separate concerns - ProgressRepository for persistence, StarCalculator for time-to-stars logic, ThemeData for styling
- **Modular Design**: Level select screen, game screen, and completion overlay as independent widgets
- **Dependency Management**: Use Riverpod providers for progress state management
- **Clear Interfaces**: Define clean navigation contracts between screens
- **Framework Independence**: Domain logic MUST NOT import Flutter packages

### Performance
- Level selection screen SHALL render at 60 FPS with 100+ levels displayed
- Star animations SHALL not cause frame drops
- Progress data SHALL load in under 100ms on app launch
- Level transitions SHALL complete in under 300ms

### Security
- Progress data stored locally only (no cloud sync in MVP)
- No user authentication required

### Reliability
- Progress data SHALL survive app termination and device restart
- App SHALL gracefully handle corrupted progress data (reset to default)

### Usability
- Level unlock status SHALL be visually obvious at a glance
- Star count SHALL be readable without tapping the level
- Navigation SHALL require maximum 2 taps to start any unlocked level
- Color contrast SHALL meet WCAG AA standards for accessibility
