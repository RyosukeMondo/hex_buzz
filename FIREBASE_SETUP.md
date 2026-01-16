# Firebase Setup Guide

This guide explains how to configure Firebase for the HexBuzz application.

## Prerequisites

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Ensure `$HOME/.pub-cache/bin` is in your PATH

## Steps to Configure Firebase

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `hexbuzz-project` (or your preferred name)
4. Follow the setup wizard

### 2. Enable Required Services

In the Firebase Console, enable the following services:

#### Authentication
- Go to Authentication → Sign-in method
- Enable "Google" provider
- Configure OAuth consent screen if needed

#### Cloud Firestore
- Go to Firestore Database
- Create database in production mode
- Choose your preferred location

#### Cloud Messaging (FCM)
- Go to Cloud Messaging
- No additional configuration needed (enabled by default)

#### Cloud Functions
- Go to Functions
- Upgrade to Blaze (pay-as-you-go) plan if needed
- Cloud Functions will be deployed later

### 3. Authenticate Firebase CLI

```bash
firebase login
```

This will open a browser for authentication.

### 4. Generate Firebase Configuration

Run the FlutterFire CLI to automatically configure all platforms:

```bash
cd /home/rmondo/repos/hex_buzz
flutterfire configure
```

This command will:
- Create or select a Firebase project
- Register your app for all platforms (Android, iOS, Web, Windows)
- Generate `lib/firebase_options.dart` with all configuration
- Create/update platform-specific config files

Select the following platforms when prompted:
- [x] android
- [x] ios
- [x] macos
- [x] web
- [x] windows

### 5. Verify Configuration

After running `flutterfire configure`, verify these files exist:

- `lib/firebase_options.dart` - Generated Firebase options
- `android/app/google-services.json` - Android configuration
- `ios/Runner/GoogleService-Info.plist` - iOS configuration
- `macos/Runner/GoogleService-Info.plist` - macOS configuration
- Web configuration is embedded in `firebase_options.dart`

### 6. Update .gitignore (if needed)

Ensure these patterns are in `.gitignore` to protect sensitive data:

```
# Firebase
google-services.json
GoogleService-Info.plist
firebase-debug.log
.firebaserc
```

**Note**: `firebase_options.dart` is typically committed as it's required for builds. Ensure your project visibility matches your security requirements.

### 7. Initialize Firebase in Your App

The app already initializes Firebase in `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 8. Test the Configuration

Run the app to verify Firebase initializes correctly:

```bash
flutter run
```

Check the console output for "Firebase initialized" message.

## Firestore Security Rules

Deploy security rules from `firestore.rules` (to be created in Phase 1.2):

```bash
firebase deploy --only firestore:rules
```

## Firestore Indexes

Deploy composite indexes from `firestore.indexes.json` (to be created in Phase 1.3):

```bash
firebase deploy --only firestore:indexes
```

## Cloud Functions

Deploy Cloud Functions (to be created in Phase 7):

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Troubleshooting

### FlutterFire CLI not found

Add to your PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Firebase CLI authentication fails

Try:

```bash
firebase logout
firebase login --reauth
```

### Platform-specific issues

**Android**: Ensure `google-services.json` is in `android/app/`
**iOS**: Ensure `GoogleService-Info.plist` is in `ios/Runner/`
**Web**: Configuration is in `firebase_options.dart`

## Current Status

✅ Firebase dependencies installed in `pubspec.yaml`
✅ Firebase initialization code in `lib/main.dart`
⚠️ `lib/firebase_options.dart` contains placeholder values
❌ Platform-specific config files not yet generated

**Next Step**: Run `flutterfire configure` to generate real configuration.

## Security Notes

- Never commit API keys for production projects to public repositories
- Use environment variables or Firebase App Check for production
- Review and deploy Firestore security rules before going live
- Enable App Check to protect backend resources from abuse
