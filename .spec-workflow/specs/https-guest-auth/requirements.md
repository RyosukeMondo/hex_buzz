# HTTPS Setup & Enhanced Guest Authentication

## Context

The HexBuzz web app is currently deployed on VPS with HTTP only, causing:
- Service Worker API failures (requires secure context)
- Flutter errors due to missing HTTPS
- Cannot use modern web features (push notifications, etc.)

Additionally, the app needs robust guest authentication that works independently from Firebase.

## Objectives

1. **Enable HTTPS** - Configure Caddy with Let's Encrypt SSL
2. **Guest Authentication** - Local-only guest accounts without Firebase dependency
3. **Hybrid Auth System** - Support both Firebase (Google Sign-In) and local guest accounts
4. **Data Isolation** - Guest data stored locally, Firebase users in Firestore

## Requirements

### 1. HTTPS Configuration

#### 1.1 Domain Setup
- Use existing VPS IP: `85.131.251.195`
- **Option A**: Use domain name (if available)
- **Option B**: Use IP-based self-signed cert for development
- **Option C**: Use Let's Encrypt with DNS challenge

#### 1.2 Caddy Configuration
- Enable automatic HTTPS with Let's Encrypt
- Configure `/hex_buzz` route with HTTPS
- Redirect HTTP → HTTPS
- Support both HTTP/1.1 and HTTP/2

#### 1.3 Certificate Management
- Automatic renewal via Caddy
- Store certs in persistent volume (Docker)
- Backup mechanism for certificates

### 2. Guest Authentication System

#### 2.1 Guest Account Creation
- **No Firebase dependency** - Works offline
- Generate unique guest ID (UUID v4)
- Store in `SharedPreferences`
- Display name: "Guest_[random_4_digits]"
- Optional: Allow guest to set custom display name

#### 2.2 Guest Data Storage
- All progress stored locally via `SharedPreferences`
- Level completion data
- Settings (sound, theme, etc.)
- High scores and statistics
- **No cloud sync for guests**

#### 2.3 Guest → Firebase Migration
- "Sign in with Google" option for guests
- Prompt to preserve guest progress
- Migrate local data to Firestore on sign-in
- Option to merge or replace cloud data

### 3. Hybrid Authentication Architecture

#### 3.1 Auth State Management
```dart
sealed class AuthState {
  const AuthState();
}

class Unauthenticated extends AuthState {}
class GuestAuth extends AuthState {
  final String guestId;
  final String displayName;
}
class FirebaseAuth extends AuthState {
  final User user;
}
```

#### 3.2 Repository Pattern
- `AuthRepository` interface (existing)
- `LocalGuestAuthRepository` - Handles guest auth
- `FirebaseAuthRepository` - Handles Google Sign-In (existing)
- `HybridAuthRepository` - Delegates to appropriate impl

#### 3.3 Data Persistence Strategy
```
Guest User:
  SharedPreferences → Local storage only

Firebase User:
  Firestore → Cloud storage
  SharedPreferences → Cache only
```

### 4. User Experience

#### 4.1 First Launch Flow
1. Show splash screen
2. Check for existing auth:
   - Guest ID in SharedPreferences → Continue as guest
   - Firebase session → Continue with Firebase
   - None → Show options
3. Options screen:
   - "Continue as Guest" (immediate, no prompts)
   - "Sign in with Google" (Firebase flow)

#### 4.2 Guest User Experience
- Play immediately, no barriers
- See progress and stats locally
- Banner: "Sign in to save progress in the cloud"
- Settings option to upgrade to Firebase

#### 4.3 Firebase User Experience
- Google Sign-In flow
- Progress synced across devices
- Access to leaderboards
- Daily challenges
- Achievement tracking

### 5. Error Handling

#### 5.1 Firebase Unavailable
- Graceful fallback to guest mode
- Show non-intrusive notification
- Retry mechanism in background
- Disable cloud features only

#### 5.2 Network Errors
- Guest mode works 100% offline
- Firebase features show "offline" status
- Queue actions for retry when online

#### 5.3 Migration Errors
- Rollback mechanism if Firestore sync fails
- Keep local data intact
- Allow retry

### 6. Security Considerations

#### 6.1 Guest Data Protection
- Guest IDs are non-identifiable
- No PII collected for guests
- Local storage only (device-bound)

#### 6.2 Firebase Data Protection
- Follow existing Firebase security rules
- User data isolated per UID
- No cross-user data access

#### 6.3 HTTPS Requirements
- All Firebase API calls over HTTPS
- Service worker requires HTTPS
- Cookie/session security

## Non-Requirements

- ❌ Guest data cloud backup
- ❌ Guest account recovery
- ❌ Multi-device sync for guests
- ❌ Anonymous Firebase auth (use pure local instead)

## Success Criteria

1. ✅ HTTPS working with valid certificate
2. ✅ Service worker loading without errors
3. ✅ Guest users can play without Firebase
4. ✅ Firebase users can sign in with Google
5. ✅ Guest → Firebase migration preserves progress
6. ✅ App works offline for guests
7. ✅ No Firebase errors when using guest mode

## Technical Constraints

- Must work with existing VPS setup
- Must use existing Caddy reverse proxy
- Must maintain backward compatibility with existing Firebase users
- Must not break existing features

## Dependencies

- Caddy v2.10.2 (installed)
- Flutter 3.35.6
- Firebase SDK (existing)
- `shared_preferences` package (existing)
- `uuid` package (add if needed)

## Implementation Priority

1. **Phase 1**: HTTPS setup (critical for web deployment)
2. **Phase 2**: Guest auth system
3. **Phase 3**: Migration flow
4. **Phase 4**: Testing and polish
