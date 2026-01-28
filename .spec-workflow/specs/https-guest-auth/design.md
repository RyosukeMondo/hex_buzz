# HTTPS Setup & Guest Authentication - Technical Design

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Internet/Browser                   │
└───────────────────────┬─────────────────────────────┘
                        │
                        │ HTTPS (Let's Encrypt)
                        ▼
┌─────────────────────────────────────────────────────┐
│              Caddy Reverse Proxy                     │
│  - Automatic HTTPS (Let's Encrypt)                  │
│  - /hex_buzz → host.docker.internal:8223            │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│           Flutter Web App (Port 8223)               │
│                                                      │
│  ┌────────────────────────────────────────────┐   │
│  │         HybridAuthRepository               │   │
│  │  ┌──────────────┐    ┌──────────────┐     │   │
│  │  │   Firebase   │    │    Guest     │     │   │
│  │  │ Auth Repo    │    │  Auth Repo   │     │   │
│  │  │ (existing)   │    │    (new)     │     │   │
│  │  └──────┬───────┘    └───────┬──────┘     │   │
│  │         │                    │            │   │
│  │         │                    │            │   │
│  │    ┌────▼──────┐      ┌─────▼─────┐     │   │
│  │    │ Firestore │      │SharedPrefs│     │   │
│  │    │  (Cloud)  │      │  (Local)  │     │   │
│  │    └───────────┘      └───────────┘     │   │
│  └────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Phase 1: HTTPS Configuration

### 1.1 Domain Configuration Options

#### Option A: Use Existing Domain (Recommended)
If you have a domain, add DNS A record:
```
hex-buzz.yourdomain.com  →  85.131.251.195
```

#### Option B: IP-Only Development
For testing without domain, use self-signed cert with:
```caddy
https://85.131.251.195 {
    tls internal
    # ... rest of config
}
```

#### Option C: Let's Encrypt with HTTP Challenge (Recommended if no domain)
Use Caddy's automatic HTTPS on IP (may have limitations)

### 1.2 Updated Caddyfile

```caddy
# Production with domain
hex-buzz.yourdomain.com {
    handle /hex_buzz* {
        uri strip_prefix /hex_buzz
        reverse_proxy host.docker.internal:8223
    }

    # Redirect root to /hex_buzz
    redir / /hex_buzz permanent

    encode gzip

    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
        # Add HSTS
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }

    log {
        output stdout
        format console
    }
}

# Auto-redirect HTTP to HTTPS
http://hex-buzz.yourdomain.com {
    redir https://hex-buzz.yourdomain.com{uri} permanent
}
```

### 1.3 Deployment Script Updates

**`enable-https.sh`**:
```bash
#!/bin/bash
# Enable HTTPS for HexBuzz

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
    echo "Usage: ./enable-https.sh hex-buzz.yourdomain.com"
    exit 1
fi

# Update Caddyfile with domain
# Reload Caddy
# Test HTTPS endpoint
```

## Phase 2: Guest Authentication System

### 2.1 Data Models

**`lib/domain/models/guest_user.dart`** (new):
```dart
class GuestUser {
  final String id;           // UUID v4
  final String displayName;  // "Guest_1234"
  final DateTime createdAt;

  GuestUser({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  // Serialization for SharedPreferences
  Map<String, dynamic> toJson();
  factory GuestUser.fromJson(Map<String, dynamic> json);
}
```

### 2.2 Repository Implementation

**`lib/data/local/local_guest_auth_repository.dart`** (new):
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/auth_repository.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/models/user.dart' as domain;

class LocalGuestAuthRepository implements AuthRepository {
  static const String _guestIdKey = 'guest_user_id';
  static const String _guestNameKey = 'guest_display_name';
  static const String _guestCreatedKey = 'guest_created_at';

  final SharedPreferences _prefs;
  final Uuid _uuid;

  LocalGuestAuthRepository({
    required SharedPreferences prefs,
    Uuid? uuid,
  }) : _prefs = prefs,
       _uuid = uuid ?? const Uuid();

  @override
  Future<AuthResult> signInAsGuest() async {
    try {
      // Check for existing guest
      String? existingId = _prefs.getString(_guestIdKey);

      if (existingId != null) {
        // Return existing guest user
        return AuthSuccess(_loadGuestUser(existingId));
      }

      // Create new guest
      final guestId = _uuid.v4();
      final displayName = _generateGuestName();
      final now = DateTime.now().toIso8601String();

      await _prefs.setString(_guestIdKey, guestId);
      await _prefs.setString(_guestNameKey, displayName);
      await _prefs.setString(_guestCreatedKey, now);

      final user = domain.User(
        id: guestId,
        displayName: displayName,
        isGuest: true,
      );

      return AuthSuccess(user);
    } catch (e) {
      return AuthFailure('Failed to create guest session: $e');
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    final guestId = _prefs.getString(_guestIdKey);
    if (guestId == null) return null;

    return _loadGuestUser(guestId);
  }

  @override
  Future<void> signOut() async {
    // Remove guest data
    await _prefs.remove(_guestIdKey);
    await _prefs.remove(_guestNameKey);
    await _prefs.remove(_guestCreatedKey);
  }

  String _generateGuestName() {
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString();
    return 'Guest_$random';
  }

  domain.User _loadGuestUser(String id) {
    return domain.User(
      id: id,
      displayName: _prefs.getString(_guestNameKey) ?? _generateGuestName(),
      isGuest: true,
    );
  }

  // Not supported for guest users
  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthFailure('Google Sign-In not available for guest users');
  }

  @override
  Stream<domain.User?> get authStateChanges => Stream.value(null);
}
```

### 2.3 Hybrid Repository

**`lib/data/hybrid_auth_repository.dart`** (new):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/auth_repository.dart';
import '../domain/models/auth_result.dart';
import '../domain/models/user.dart' as domain;
import 'firebase/firebase_auth_repository.dart';
import 'local/local_guest_auth_repository.dart';

class HybridAuthRepository implements AuthRepository {
  final FirebaseAuthRepository _firebaseRepo;
  final LocalGuestAuthRepository _guestRepo;

  AuthRepository _activeRepo;

  HybridAuthRepository({
    required FirebaseAuthRepository firebaseRepo,
    required LocalGuestAuthRepository guestRepo,
  }) : _firebaseRepo = firebaseRepo,
       _guestRepo = guestRepo,
       _activeRepo = guestRepo; // Default to guest

  @override
  Future<AuthResult> signInAsGuest() async {
    _activeRepo = _guestRepo;
    return _guestRepo.signInAsGuest();
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Get guest data for migration if exists
    final guestUser = await _guestRepo.getCurrentUser();

    // Switch to Firebase repo
    _activeRepo = _firebaseRepo;
    final result = await _firebaseRepo.signInWithGoogle();

    // If successful and there was guest data, migrate it
    if (result is AuthSuccess && guestUser != null) {
      await _migrateGuestDataToFirebase(guestUser, result.user);
    }

    return result;
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    // Check Firebase first
    final firebaseUser = await _firebaseRepo.getCurrentUser();
    if (firebaseUser != null) {
      _activeRepo = _firebaseRepo;
      return firebaseUser;
    }

    // Check guest
    final guestUser = await _guestRepo.getCurrentUser();
    if (guestUser != null) {
      _activeRepo = _guestRepo;
      return guestUser;
    }

    return null;
  }

  @override
  Future<void> signOut() async {
    await _activeRepo.signOut();
  }

  @override
  Stream<domain.User?> get authStateChanges {
    // Merge both streams, prioritizing Firebase
    return _firebaseRepo.authStateChanges;
  }

  Future<void> _migrateGuestDataToFirebase(
    domain.User guestUser,
    domain.User firebaseUser,
  ) async {
    // TODO: Implement data migration logic
    // - Copy progress from SharedPreferences to Firestore
    // - Copy level completion data
    // - Copy statistics
    // - Clean up local guest data
  }
}
```

### 2.4 Provider Updates

**`lib/presentation/providers/auth_provider.dart`** (update):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/firebase/firebase_auth_repository.dart';
import '../../data/local/local_guest_auth_repository.dart';
import '../../data/hybrid_auth_repository.dart';
import '../../domain/models/user.dart';

// Shared preferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Guest auth repository
final guestAuthRepositoryProvider = Provider<LocalGuestAuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value!;
  return LocalGuestAuthRepository(prefs: prefs);
});

// Firebase auth repository (existing)
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Hybrid auth repository
final authRepositoryProvider = Provider<HybridAuthRepository>((ref) {
  return HybridAuthRepository(
    firebaseRepo: ref.watch(firebaseAuthRepositoryProvider),
    guestRepo: ref.watch(guestAuthRepositoryProvider),
  );
});

// Current user state
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});
```

## Phase 3: UI Updates

### 3.1 Welcome Screen

**`lib/presentation/screens/welcome/welcome_screen.dart`** (new):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo and title
            Text('HexBuzz', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 48),

            // Guest button - prominent
            ElevatedButton(
              onPressed: () => _signInAsGuest(ref, context),
              child: const Text('Continue as Guest'),
            ),
            const SizedBox(height: 16),

            // Google Sign-In button
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              onPressed: () => _signInWithGoogle(ref, context),
              label: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 24),

            // Info text
            Text(
              'Guest mode: Play immediately, progress saved locally',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInAsGuest(WidgetRef ref, BuildContext context) async {
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInAsGuest();

    if (result is AuthSuccess) {
      // Navigate to main app
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _signInWithGoogle(WidgetRef ref, BuildContext context) async {
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInWithGoogle();

    if (result is AuthSuccess) {
      Navigator.of(context).pushReplacementNamed('/');
    } else if (result is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}
```

### 3.2 Guest Upgrade Banner

**`lib/presentation/widgets/guest_upgrade_banner.dart`** (new):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class GuestUpgradeBanner extends ConsumerWidget {
  const GuestUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    // Only show for guest users
    if (user == null || !user.isGuest) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sign in to save your progress in the cloud',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
          TextButton(
            onPressed: () => _upgradeToFirebase(ref, context),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradeToFirebase(WidgetRef ref, BuildContext context) async {
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInWithGoogle();

    if (result is AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed in! Your progress has been saved to the cloud.')),
      );
    }
  }
}
```

## Phase 4: Testing Strategy

### 4.1 Unit Tests

**`test/data/local/local_guest_auth_repository_test.dart`**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hex_buzz/data/local/local_guest_auth_repository.dart';

void main() {
  group('LocalGuestAuthRepository', () {
    late LocalGuestAuthRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = LocalGuestAuthRepository(prefs: prefs);
    });

    test('signInAsGuest creates new guest user', () async {
      final result = await repository.signInAsGuest();

      expect(result, isA<AuthSuccess>());
      final user = (result as AuthSuccess).user;
      expect(user.isGuest, true);
      expect(user.displayName, startsWith('Guest_'));
    });

    test('signInAsGuest returns existing guest', () async {
      // First sign in
      final result1 = await repository.signInAsGuest();
      final user1 = (result1 as AuthSuccess).user;

      // Second sign in
      final result2 = await repository.signInAsGuest();
      final user2 = (result2 as AuthSuccess).user;

      expect(user1.id, user2.id);
    });

    test('signOut removes guest data', () async {
      await repository.signInAsGuest();
      await repository.signOut();

      final user = await repository.getCurrentUser();
      expect(user, isNull);
    });
  });
}
```

### 4.2 Integration Tests

Test scenarios:
1. Guest user completes levels → progress saved locally
2. Guest upgrades to Firebase → progress migrated
3. Firebase user signs out → can continue as guest
4. App works offline in guest mode

### 4.3 Manual Testing Checklist

- [ ] HTTPS loads without certificate warnings
- [ ] Service worker loads successfully
- [ ] Guest sign-in works immediately
- [ ] Guest progress persists across app restarts
- [ ] Google Sign-In flow works
- [ ] Guest → Firebase migration preserves data
- [ ] App works offline as guest
- [ ] Firebase features disabled gracefully for guests

## Security Considerations

### HTTPS Security
- Use strong TLS settings (Caddy default: TLS 1.2+)
- HSTS header enabled
- Certificate auto-renewal configured
- Monitoring for cert expiry

### Guest Data Security
- No PII collected for guests
- Data stored only on device
- No server-side tracking
- Clear privacy policy

### Firebase Security
- Existing Firestore rules maintained
- User data isolation enforced
- API keys exposed (normal for web)
- Rate limiting on auth endpoints

## Performance Considerations

- Guest auth is instant (no network)
- Firebase auth: ~1-2s (Google OAuth)
- Data migration: background async operation
- Service worker caching improves load times

## Rollout Plan

### Stage 1: HTTPS (Week 1)
1. Configure domain DNS
2. Update Caddyfile
3. Test HTTPS endpoint
4. Update deployment scripts
5. Deploy to production

### Stage 2: Guest Auth (Week 2)
1. Implement `LocalGuestAuthRepository`
2. Add welcome screen
3. Update auth provider
4. Unit tests
5. Deploy guest-only mode

### Stage 3: Hybrid System (Week 3)
1. Implement `HybridAuthRepository`
2. Data migration logic
3. Guest upgrade UI
4. Integration tests
5. Full deployment

### Stage 4: Polish (Week 4)
1. UI/UX improvements
2. Error handling refinement
3. Performance optimization
4. Documentation
5. User testing

## Monitoring & Maintenance

- Monitor certificate expiry (Caddy handles auto-renewal)
- Track guest vs Firebase user ratios
- Monitor migration success rate
- Error logging for auth failures
- Analytics on auth method preference
