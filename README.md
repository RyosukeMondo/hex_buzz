# HexBuzz

A hexagonal puzzle game where you draw a single path through all cells.

## Features

### 🎮 Core Gameplay
- Draw a continuous path through all hexagonal cells
- Progressive difficulty with increasing grid sizes
- Earn 1-3 stars based on performance
- Multiple levels with unique puzzles

### 🐝 Daily Challenge
- New puzzle every day at midnight UTC
- **One attempt per day** - make it count!
- Compete on daily leaderboards
- Share results on social media (Twitter, Misskey, Facebook)
- Push notifications when new challenges are available
- Fair play enforcement with backend validation

**Learn more**: [Daily Challenge Documentation](docs/DAILY_CHALLENGE.md)

### 🏆 Features
- Local and Firebase authentication
- Guest mode for instant play
- Progress tracking and save system
- Clean, modern UI with honey/bee theme
- Cross-platform (iOS, Android, Web, Desktop)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project (for backend features)
- Node.js (for Cloud Functions)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/hex_buzz.git
   cd hex_buzz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd functions && npm install && cd ..
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore, Authentication, Cloud Functions, and Cloud Messaging
   - Download and add Firebase configuration files:
     - `google-services.json` (Android)
     - `GoogleService-Info.plist` (iOS)
     - Firebase config for web

4. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm run deploy
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

The app requires the following Firebase services:
- **Firestore**: Database for challenges, completions, and leaderboards
- **Authentication**: User accounts and guest mode
- **Cloud Functions**: Backend validation and notification triggers
- **Cloud Messaging**: Push notifications for daily challenges

See [Firebase Setup Guide](docs/FIREBASE_SETUP.md) for detailed configuration.

## Project Structure

```
lib/
├── core/               # Core utilities (logging, errors, DI)
├── data/               # Data layer (repositories, Firebase)
├── domain/             # Domain layer (models, interfaces)
├── presentation/       # UI layer (screens, widgets, providers)
├── services/           # Services (share, notifications)
└── main.dart           # App entry point

functions/              # Cloud Functions
├── src/
│   ├── functions/      # Function definitions
│   ├── services/       # Backend services
│   └── utils/          # Utilities
└── test/               # Cloud Function tests

integration_test/       # E2E integration tests
test/                   # Unit and widget tests
```

## Testing

### Run all tests
```bash
flutter test                                      # Unit and widget tests
flutter test integration_test/                   # Integration tests
cd functions && npm test                         # Cloud Function tests
```

### Test coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html     # Generate HTML report
```

## Daily Challenge

The Daily Challenge feature provides a new puzzle every day with competitive leaderboards. Key features:

- ✅ **One attempt per day** - no retries until tomorrow
- ⏱️ **Timer cannot restart** - your first attempt time is final
- 🔔 **Push notifications** - get notified when challenges are available
- 🎯 **Real-time leaderboards** - see your rank immediately
- 🌐 **Social sharing** - share your results on Twitter, Misskey, Facebook
- 🛡️ **Backend validation** - prevents cheating with server-side checks

See [docs/DAILY_CHALLENGE.md](docs/DAILY_CHALLENGE.md) for complete documentation.

## Documentation

- [Architecture Guidelines](docs/ARCHITECTURE_GUIDELINES.md)
- [Daily Challenge](docs/DAILY_CHALLENGE.md)
- [User Guide](docs/USER_GUIDE.md)
- [Deployment](docs/PRODUCTION_DEPLOYMENT.md)
- [CI/CD](docs/CICD.md)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
