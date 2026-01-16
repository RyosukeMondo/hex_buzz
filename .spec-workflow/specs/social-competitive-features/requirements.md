# Requirements Document: Social & Competitive Features

## Introduction

This spec covers the implementation of social and competitive game features including Google Authentication, Global Leaderboards, Daily Challenge System with Push Notifications, and Microsoft Store deployment. These features transform HexBuzz from a single-player puzzle game into an engaging competitive social experience that drives daily engagement and player retention.

## Alignment with Product Vision

This feature directly supports the product goals outlined in product.md:
- **User Retention**: Daily challenges and leaderboards drive repeat play (targeting D1: 50%+, D7: 25%+, D30: 12%+)
- **Global Leaderboard**: Implements the "Future Vision" feature from product.md
- **Cross-Platform Play**: Extends to Windows via Microsoft Store deployment
- **Business Objectives**: Builds user engagement through competitive mechanics
- **AI Agent-First Development**: CLI/REST API first for all features before UI

## Architectural Principles & Criteria

This implementation MUST adhere to the following principles defined in tech.md and structure.md:

### Development Principles (Priority Order)

| Principle | Application in This Feature | Priority |
|-----------|----------------------------|----------|
| **KISS** | Simple OAuth flow, straightforward leaderboard API, minimal notification logic | **Highest** |
| **SOLID** | Single Responsibility: AuthService (authentication), LeaderboardService (scoring), NotificationService (push), separate repositories | High |
| **SLAP** | Each function at one abstraction level - UI doesn't know Firebase details, services don't handle UI state | High |
| **DI** | All external dependencies injected (Firebase, Google Auth, notification APIs) | High |
| **SSOT** | User authentication state as single source of truth, leaderboard data cached with single source | Medium |

### Module Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                      presentation/                          │
│  - AuthScreen (Google Sign-In UI)                          │
│  - LeaderboardScreen (rankings, daily challenges)          │
│  - AuthProvider, LeaderboardProvider (Riverpod)            │
│  - Can import: domain/models, domain/services, core/*      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        domain/                               │
│  - User model (extended with social data)                  │
│  - LeaderboardEntry, DailyChallenge models                 │
│  - AuthRepository, LeaderboardRepository interfaces        │
│  - StarCalculator (existing, reused)                       │
│  - No Flutter imports - pure Dart, fully testable          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         data/                                │
│  - FirebaseAuthRepository (Google Sign-In impl)            │
│  - FirestoreLeaderboardRepository (Cloud Firestore impl)   │
│  - LocalCacheRepository (offline leaderboard cache)        │
│  - NotificationRepository (push notification impl)         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        debug/                                │
│  - CLI: auth login, auth logout, leaderboard get           │
│  - CLI: daily-challenge generate, notify test              │
│  - REST API: POST /api/auth/login, GET /api/leaderboard    │
│  - Enable AI agent to test features without UI             │
└─────────────────────────────────────────────────────────────┘
```

### AI Agent-First Development Order

Per product.md, implementation MUST follow this order:
1. **First**: CLI commands for auth and leaderboard (`auth login`, `leaderboard submit`, `daily-challenge`)
2. **Second**: REST API endpoints (`POST /api/auth/google`, `GET /api/leaderboard`, `POST /api/scores`)
3. **Third**: Domain models and services (User, LeaderboardEntry, DailyChallenge)
4. **Fourth**: Firebase/Cloud integration (Firestore, Cloud Functions, FCM)
5. **Fifth**: UI components (AuthScreen, LeaderboardScreen)
6. **Sixth**: Microsoft Store packaging and deployment

### Code Quality Criteria (from tech.md)

| Metric | Limit | Enforcement |
|--------|-------|-------------|
| **File size** | Max 500 lines | Pre-commit hook |
| **Function size** | Max 50 lines | Pre-commit hook |
| **Cyclomatic complexity** | Max 10 per function | dart_code_metrics |
| **Test coverage** | Min 80% (90% for auth/payment) | CI/CD |

### Testability Requirements

- All auth logic MUST be testable without Firebase (use mocks)
- Leaderboard ranking MUST be testable with deterministic data
- Notification delivery MUST be mockable for tests
- CLI commands MUST be testable via unit tests
- Daily challenge generation MUST be deterministic for testing

## Requirements

### Requirement 1: Google Authentication

**User Story:** As a player, I want to sign in with my Google account, so that my progress and scores are saved across devices and I can compete on leaderboards.

#### Acceptance Criteria

1. WHEN the app first launches AND user is not logged in THEN the system SHALL display a welcome screen with "Sign in with Google" button
2. WHEN the user taps "Sign in with Google" THEN the system SHALL open Google OAuth consent screen
3. WHEN the user grants permission THEN the system SHALL:
   - Receive Google ID token
   - Create or retrieve user profile in Firestore
   - Store authentication credentials securely
   - Navigate to level select screen
4. WHEN authentication succeeds THEN the system SHALL display user's name and avatar in level select header
5. WHEN the user is already logged in THEN the system SHALL restore session on app launch without requiring re-login
6. WHEN the user logs out THEN the system SHALL:
   - Clear authentication credentials
   - Navigate back to welcome screen
   - Preserve local progress data (do not delete)
7. IF authentication fails THEN the system SHALL display error message and allow retry
8. WHEN the user is logged in THEN the system SHALL sync progress to cloud (Firestore)

### Requirement 2: Global Leaderboards

**User Story:** As a player, I want to see how my scores compare to other players worldwide, so that I feel motivated to improve and compete.

#### Acceptance Criteria

1. WHEN the user taps "Leaderboard" button on level select screen THEN the system SHALL navigate to leaderboard screen
2. WHEN the leaderboard screen loads THEN the system SHALL display:
   - Top 100 global players ranked by total stars
   - Each entry showing: rank, username, avatar, total stars, country flag (optional)
   - User's own rank and score prominently highlighted
   - Last updated timestamp
3. WHEN displaying leaderboard THEN the system SHALL support filtering by:
   - Global (all players)
   - Friends only (future enhancement - show placeholder)
   - Daily challenge leaderboard
4. WHEN the user completes a level THEN the system SHALL:
   - Submit score to Firestore if it improves their total stars
   - Update leaderboard rankings asynchronously
   - Show rank change notification (e.g., "You moved up 5 ranks!")
5. WHEN offline THEN the system SHALL display cached leaderboard data with "Offline" indicator
6. WHEN leaderboard data is stale (>5 minutes) THEN the system SHALL refresh from Firestore
7. IF leaderboard fails to load THEN the system SHALL display cached data or friendly error message

### Requirement 3: Daily Challenge System

**User Story:** As a player, I want a new puzzle challenge every day, so that I have a reason to return daily and compete with others on the same puzzle.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL check if today's daily challenge is available
2. WHEN a new day starts (00:00 UTC) THEN the system SHALL:
   - Generate a new daily challenge level (procedurally or from curated pool)
   - Reset all players' daily challenge attempts
   - Notify players via push notification: "Today's challenge is ready!"
3. WHEN the user taps "Daily Challenge" on level select screen THEN the system SHALL:
   - Navigate to daily challenge level
   - Display challenge metadata: date, difficulty, completion count
4. WHEN the user completes the daily challenge THEN the system SHALL:
   - Record completion time and stars
   - Submit score to daily challenge leaderboard
   - Display rank among all players who completed today's challenge
   - Show "Challenge Complete" badge
5. WHEN the daily challenge is already completed THEN the system SHALL:
   - Display "Completed" status with achieved rank
   - Allow replay but not resubmit score
6. WHEN the user has not completed yesterday's challenge THEN the system SHALL mark it as "Expired"
7. IF the user completes the daily challenge within top 10% THEN the system SHALL award bonus stars/coins

### Requirement 4: Push Notifications

**User Story:** As a player, I want to receive notifications about daily challenges and ranking changes, so that I stay engaged with the game.

#### Acceptance Criteria

1. WHEN the user first logs in THEN the system SHALL request push notification permission
2. WHEN permission is granted THEN the system SHALL register device token with Firebase Cloud Messaging (FCM)
3. WHEN a new daily challenge is available (00:00 UTC) THEN the system SHALL send push notification:
   - Title: "New Daily Challenge!"
   - Body: "Can you beat today's puzzle? Compete for the top spot!"
   - Deep link to daily challenge screen
4. WHEN the user's leaderboard rank changes significantly (±10 ranks) THEN the system SHALL send notification:
   - Title: "Rank Update!"
   - Body: "You moved up to rank #42! Keep playing to climb higher."
5. WHEN the user hasn't played in 3 days THEN the system SHALL send re-engagement notification:
   - Title: "We miss you!"
   - Body: "3 new daily challenges are waiting for you!"
6. WHEN the user taps notification THEN the system SHALL:
   - Open app to relevant screen (daily challenge, leaderboard, etc.)
   - Track notification engagement metrics
7. WHEN notification settings THEN the system SHALL allow users to:
   - Toggle daily challenge notifications
   - Toggle rank change notifications
   - Toggle re-engagement notifications
   - Disable all notifications

### Requirement 5: Microsoft Store Deployment

**User Story:** As a Windows user, I want to install HexBuzz from the Microsoft Store, so that I can play on my PC with automatic updates.

#### Acceptance Criteria

1. WHEN packaging for Microsoft Store THEN the system SHALL:
   - Use Flutter's MSIX packaging (flutter build windows --release)
   - Include proper app manifest with capabilities (internetClient, notifications)
   - Sign with valid Microsoft Store certificate
2. WHEN the app runs on Windows THEN the system SHALL:
   - Display properly on desktop screen sizes (720p, 1080p, 4K)
   - Support mouse and keyboard input
   - Support touch input on touch-enabled Windows devices
3. WHEN submitted to Microsoft Store THEN the package SHALL:
   - Pass Windows App Certification Kit (WACK) validation
   - Include required assets: app icon (multiple sizes), screenshots, store listing
   - Include privacy policy URL (for data collection)
4. WHEN the user installs from Microsoft Store THEN the app SHALL:
   - Install in user's chosen directory
   - Create start menu shortcut
   - Support automatic updates via Microsoft Store
5. WHEN the Windows app uses notifications THEN the system SHALL use Windows Notification Service (WNS) instead of FCM
6. WHEN displaying UI on Windows THEN the system SHALL:
   - Use Windows-native window controls (minimize, maximize, close)
   - Support window resizing with responsive layout
   - Follow Windows 11 design guidelines where applicable

### Requirement 6: Cloud Infrastructure (Firebase/Firestore)

**User Story:** As the system, I need cloud infrastructure to store user data, leaderboards, and handle authentication, so that features work reliably at scale.

#### Acceptance Criteria

1. WHEN setting up Firebase THEN the project SHALL include:
   - Firebase Authentication (Google provider enabled)
   - Cloud Firestore (database for users, scores, challenges)
   - Cloud Functions (for leaderboard calculations, daily challenge generation)
   - Firebase Cloud Messaging (for push notifications)
   - Firebase Hosting (for privacy policy, terms of service)
2. WHEN storing user data THEN the system SHALL use Firestore schema:
   ```
   users/{userId}
     - uid: string
     - email: string
     - displayName: string
     - photoURL: string
     - totalStars: number
     - completedLevels: number
     - createdAt: timestamp
     - lastLoginAt: timestamp
   ```
3. WHEN storing leaderboard data THEN the system SHALL use Firestore schema:
   ```
   leaderboard/{userId}
     - userId: string
     - username: string
     - avatar: string
     - totalStars: number
     - rank: number (computed)
     - updatedAt: timestamp

   dailyChallenges/{date}
     - date: string (YYYY-MM-DD)
     - levelData: object (Level serialized)
     - completions: number
     - entries: subcollection
       {userId}
         - userId: string
         - username: string
         - stars: number
         - time: number (milliseconds)
         - rank: number
         - completedAt: timestamp
   ```
4. WHEN computing leaderboard ranks THEN the system SHALL use Cloud Function triggered on score update
5. WHEN generating daily challenges THEN the system SHALL use scheduled Cloud Function (daily at 00:00 UTC)
6. WHEN accessing Firestore THEN the system SHALL enforce security rules:
   - Users can only read/write their own user document
   - Users can read global leaderboard but not write directly
   - Score submissions validated server-side via Cloud Function
7. IF Firestore costs exceed budget THEN the system SHALL implement caching and pagination

### Requirement 7: Debug/CLI Interface (AI Agent Support)

**User Story:** As an AI agent developer, I want CLI and API access to auth, leaderboard, and notification features, so that I can test without UI interaction.

#### Acceptance Criteria

1. WHEN running `honeycomb-cli auth login --token <google-token>` THEN the system SHALL authenticate with Google ID token
2. WHEN running `honeycomb-cli auth logout` THEN the system SHALL clear authentication state
3. WHEN running `honeycomb-cli auth whoami` THEN the system SHALL output current user JSON
4. WHEN running `honeycomb-cli leaderboard get --top 10` THEN the system SHALL output top 10 leaderboard entries as JSON
5. WHEN running `honeycomb-cli leaderboard submit --stars 150` THEN the system SHALL submit score to leaderboard
6. WHEN running `honeycomb-cli daily-challenge generate --date 2026-01-20` THEN the system SHALL generate and store daily challenge for date
7. WHEN running `honeycomb-cli daily-challenge get-today` THEN the system SHALL output today's challenge data as JSON
8. WHEN running `honeycomb-cli notify test --user-id abc123 --message "Test"` THEN the system SHALL send test notification
9. WHEN calling `POST /api/auth/google` with ID token THEN the system SHALL authenticate and return user JSON
10. WHEN calling `GET /api/leaderboard?limit=50` THEN the system SHALL return leaderboard entries
11. WHEN calling `POST /api/scores` with level completion THEN the system SHALL update leaderboard
12. WHEN calling `GET /api/daily-challenge` THEN the system SHALL return today's challenge
13. WHEN calling `POST /api/daily-challenge/complete` with result THEN the system SHALL record completion

## Non-Functional Requirements

### Code Architecture and Modularity
- **Single Responsibility Principle**: Separate concerns - AuthRepository (authentication), LeaderboardRepository (scoring), NotificationService (push)
- **Modular Design**: Auth, leaderboard, notifications as independent modules with clear interfaces
- **Dependency Management**: Firebase dependencies injected, mockable for testing
- **Clear Interfaces**: Clean contracts between domain layer and Firebase implementation
- **Framework Independence**: Domain logic MUST NOT import Flutter or Firebase packages directly

### Performance
- Leaderboard queries SHALL return results in <2 seconds (with pagination)
- Authentication flow SHALL complete in <3 seconds on good network
- Firestore reads SHALL be minimized via caching (max 1 read per 5 minutes for leaderboard)
- Daily challenge generation SHALL complete in <5 seconds
- Push notifications SHALL be delivered within 30 seconds of trigger

### Security
- Google OAuth tokens SHALL be stored securely using flutter_secure_storage
- Firestore security rules SHALL prevent unauthorized data access
- User PII (email, photo) SHALL comply with GDPR/privacy regulations
- API endpoints SHALL validate authentication tokens server-side
- No secrets/API keys in client code - use Firebase App Check for security

### Reliability
- Authentication SHALL handle network failures gracefully (offline mode)
- Leaderboard SHALL work offline with cached data (stale data indicator)
- Daily challenge generation SHALL have fallback if Cloud Function fails
- Push notifications SHALL retry failed deliveries (up to 3 attempts)

### Scalability
- Firestore schema SHALL support millions of users (sharding if needed)
- Leaderboard queries SHALL use pagination (50 entries per page)
- Cloud Functions SHALL handle concurrent score submissions efficiently
- Daily challenge SHALL support 100k+ simultaneous participants

### Usability
- Google Sign-In button SHALL follow Google's brand guidelines
- Leaderboard SHALL be visually appealing with smooth scrolling
- User's rank SHALL be always visible (sticky header)
- Error messages SHALL be user-friendly and actionable
- Microsoft Store app SHALL have 4.5+ star rating goal

### Privacy & Compliance
- Privacy policy SHALL be accessible before sign-in
- User data deletion SHALL be supported (GDPR "right to be forgotten")
- Analytics tracking SHALL be opt-in
- Push notification permission SHALL be requested with clear explanation

### Microsoft Store Requirements
- App SHALL pass WACK validation without errors
- Store listing SHALL include: 4+ screenshots, app description, privacy policy URL
- App icon SHALL meet Microsoft Store icon requirements (44x44 to 620x620)
- App SHALL support Windows 10 version 1809 and later
- Package SHALL be signed with Microsoft Store certificate
