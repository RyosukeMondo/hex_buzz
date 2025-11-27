# Product Overview

## Product Purpose
Honeycomb One Pass (ハニカムワンパス) is a one-stroke drawing puzzle game where players navigate through a honeycomb (hexagonal grid) structure. The game challenges players to draw a single continuous path from a starting checkpoint to an ending checkpoint while covering every cell in the grid exactly once.

## Target Users
- **Primary**: Casual puzzle game players of all ages (children to adults)
- **Secondary**: Players seeking brain-training or relaxation games
- **Pain Points Addressed**:
  - Need for quick, satisfying puzzle experiences
  - Desire for games that are easy to learn but progressively challenging
  - Want for visually appealing, stress-free gaming experiences

## Key Features

1. **Honeycomb Grid Gameplay**: Navigate hexagonal grids with numbered checkpoints (01, 02, 03...) that must be visited in order while covering all cells
2. **Progressive Difficulty**: Grid sizes from 4x4 (tutorial) to 16x16 (expert), with optimized checkpoint counts for each level
3. **Visual Path Effects**: Dynamic color-changing path visualization as the stroke lengthens
4. **Celebration Animations**: Pachinko/slot-machine style visual effects on level completion (toggleable)
5. **Undo/Reset Functionality**: Backtrack by retracing path; full reset available anytime
6. **Cross-Platform Play**: Available on Web, Android, iOS, Linux, and Windows

## Business Objectives

- Provide a free, ad-supported casual gaming experience
- Build user engagement through progressively challenging levels
- Establish foundation for future global leaderboard feature
- Create a visually distinctive puzzle game brand

## Development Philosophy: AI Agent-First

**Goal**: Achieve extremely high developer experience through fully autonomous AI Agent development.

### Core Principles
1. **CLI/REST API First**: Build all features with CLI and REST API interfaces before UI, enabling AI agents to interact, test, and debug programmatically
2. **Comprehensive Logging**: Implement structured logging throughout the application so AI agents can analyze behavior and diagnose issues autonomously
3. **Autonomous Feedback Loop**: AI agents should be able to:
   - Run tests and receive structured results
   - Query game state via REST API
   - Validate level generation algorithms via CLI
   - Get immediate feedback without human intervention

### Development Priority Order
When implementing any feature:
1. **First**: Build CLI/REST API debug capabilities
2. **Second**: Add comprehensive logging and error reporting
3. **Third**: Enable AI agent autonomous testing and validation
4. **Fourth**: Implement UI/visual components
5. **Last Resort**: Ask human developer only for decisions truly requiring human judgment

### Benefits
- Faster iteration cycles through autonomous AI development
- Reduced context-switching for human developers
- Self-documenting codebase through API-first design
- Easier debugging and maintenance

## Success Metrics

- **User Retention**: 30-day retention rate target
- **Session Length**: Average time spent per session
- **Level Completion**: Percentage of users completing each difficulty tier
- **Cross-Platform Adoption**: Distribution of users across platforms

## Product Principles

1. **Simplicity First**: No text-based tutorials needed; gameplay should be self-explanatory through visual design
2. **Frustration-Free**: System prevents invalid moves automatically; users cannot make mistakes that require restart
3. **Universal Accessibility**: No localization needed - pure visual/icon-based UI works across all languages
4. **Performance Priority**: Smooth experience on low-spec devices; visual effects are optional

## Monitoring & Visibility

- **Dashboard Type**: In-game level select screen with completion status
- **Real-time Updates**: Immediate visual feedback during gameplay (path drawing, checkpoints)
- **Key Metrics Displayed**: Best completion time per level, current level progress
- **Sharing Capabilities**: Future leaderboard integration for global rankings

## Future Vision

### Potential Enhancements
- **Global Leaderboard**: Compare completion times with players worldwide (cloud-based)
- **Daily Challenges**: Procedurally generated daily puzzles
- **Achievement System**: Unlock badges for completing levels within time targets
- **Social Features**: Share completed paths, challenge friends
