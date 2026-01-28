# HTTPS Setup & Guest Authentication - Implementation Tasks

## Phase 1: HTTPS Configuration (Priority: Critical)

### Task 1.1: Domain Setup
**Objective**: Configure domain or IP for HTTPS access

**Steps**:
1. Decide on domain strategy:
   - Option A: Use subdomain (hex-buzz.yourdomain.com)
   - Option B: Use Cloudflare Tunnel for HTTPS without domain
   - Option C: Use self-signed cert for development
2. If using domain: Add DNS A record pointing to 85.131.251.195
3. Wait for DNS propagation (use `dig` to verify)

**Deliverable**: Domain resolving to VPS IP

**Estimated**: 30 minutes (excluding DNS propagation)

---

### Task 1.2: Update Caddy Configuration
**Objective**: Enable automatic HTTPS in Caddy

**Steps**:
1. Update `/home/rmondo/repos/reverse-proxy/Caddyfile`:
   ```caddy
   hex-buzz.yourdomain.com {
       handle /hex_buzz* {
           uri strip_prefix /hex_buzz
           reverse_proxy host.docker.internal:8223
       }
       # ... rest of config
   }
   ```
2. Test Caddyfile syntax: `caddy fmt --overwrite Caddyfile`
3. Reload Caddy: `docker exec central-caddy caddy reload`
4. Verify certificate issuance in logs
5. Test HTTPS endpoint

**Files**:
- `/home/rmondo/repos/reverse-proxy/Caddyfile`

**Deliverable**: Working HTTPS endpoint

**Estimated**: 1 hour

---

### Task 1.3: Create HTTPS Deployment Scripts
**Objective**: Automate HTTPS setup and certificate management

**Steps**:
1. Create `enable-https.sh`:
   - Accept domain as parameter
   - Update Caddyfile with domain
   - Reload Caddy
   - Test HTTPS
   - Display certificate info
2. Create `check-https.sh`:
   - Check certificate validity
   - Check expiry date
   - Test HTTPS endpoint
   - Check service worker loading
3. Update existing deployment scripts to use HTTPS

**Files**:
- `enable-https.sh` (new)
- `check-https.sh` (new)
- Update `deploy.sh`, `check-deployment.sh`

**Deliverable**: Automated HTTPS setup scripts

**Estimated**: 1 hour

---

### Task 1.4: Update Flutter Build Configuration
**Objective**: Configure Flutter for HTTPS base URL

**Steps**:
1. Update `deploy.sh` to use HTTPS URL in build
2. Update `web/index.html` if needed for HTTPS
3. Test service worker loading over HTTPS
4. Verify all assets load correctly

**Files**:
- `deploy.sh`
- `web/index.html`

**Deliverable**: Flutter app working over HTTPS

**Estimated**: 30 minutes

---

## Phase 2: Guest Authentication Implementation

### Task 2.1: Implement Local Guest Auth Repository
**Objective**: Create local-only guest authentication

**Steps**:
1. Add `uuid` package to `pubspec.yaml`
2. Create `lib/data/local/local_guest_auth_repository.dart`:
   - Implement `AuthRepository` interface
   - Use `SharedPreferences` for storage
   - Generate UUID for guest ID
   - Generate guest display name
3. Implement methods:
   - `loginAsGuest()` - Create or load guest
   - `getCurrentUser()` - Load from SharedPreferences
   - `signOut()` - Clear guest data
   - Stub other methods with appropriate errors
4. Add serialization helpers

**Files**:
- `pubspec.yaml` (add uuid package)
- `lib/data/local/local_guest_auth_repository.dart` (new)

**Deliverable**: Working guest auth repository

**Estimated**: 2 hours

---

### Task 2.2: Update User Model for Guest Support
**Objective**: Add guest user support to domain models

**Steps**:
1. Update `lib/domain/models/user.dart`:
   - Add `isGuest` boolean field
   - Update constructors
   - Update serialization
   - Add `isAnonymous` getter for compatibility
2. Update any code that assumes all users are Firebase users
3. Add tests for guest user model

**Files**:
- `lib/domain/models/user.dart`
- `test/domain/models/user_test.dart`

**Deliverable**: User model supporting guest users

**Estimated**: 1 hour

---

### Task 2.3: Create Hybrid Auth Repository
**Objective**: Coordinate between Firebase and Guest auth

**Steps**:
1. Create `lib/data/hybrid_auth_repository.dart`:
   - Wrap both Firebase and Guest repositories
   - Implement repository selection logic
   - Handle auth state switching
   - Implement data migration stub
2. Implement methods:
   - `loginAsGuest()` - Delegate to guest repo
   - `signInWithGoogle()` - Delegate to Firebase repo
   - `getCurrentUser()` - Check both repos
   - `authStateChanges()` - Merge streams
3. Add switching logic between repos

**Files**:
- `lib/data/hybrid_auth_repository.dart` (new)

**Deliverable**: Working hybrid auth repository

**Estimated**: 3 hours

---

### Task 2.4: Update Auth Providers
**Objective**: Wire up new auth system with Riverpod

**Steps**:
1. Update `lib/presentation/providers/auth_provider.dart`:
   - Add `sharedPreferencesProvider`
   - Add `guestAuthRepositoryProvider`
   - Add `hybridAuthRepositoryProvider`
   - Update `authRepositoryProvider` to use hybrid
   - Update `currentUserProvider`
2. Ensure all existing providers work with new system
3. Test provider initialization

**Files**:
- `lib/presentation/providers/auth_provider.dart`

**Deliverable**: Updated auth providers

**Estimated**: 1 hour

---

### Task 2.5: Create Welcome/Auth Screen
**Objective**: UI for choosing auth method

**Steps**:
1. Create `lib/presentation/screens/welcome/welcome_screen.dart`:
   - Design layout with app branding
   - "Continue as Guest" button (primary)
   - "Sign in with Google" button (secondary)
   - Info text explaining guest mode
2. Implement button handlers:
   - Guest: Call `loginAsGuest()`, navigate to app
   - Google: Call `signInWithGoogle()`, navigate to app
3. Add loading states and error handling
4. Style with HoneyTheme

**Files**:
- `lib/presentation/screens/welcome/welcome_screen.dart` (new)

**Deliverable**: Welcome screen UI

**Estimated**: 2 hours

---

### Task 2.6: Update App Initialization Flow
**Objective**: Check auth state on app startup

**Steps**:
1. Update `lib/main.dart`:
   - Check for existing auth (guest or Firebase)
   - Show welcome screen if unauthenticated
   - Show main app if authenticated
2. Handle Firebase initialization errors gracefully
3. Fallback to guest mode if Firebase unavailable
4. Update route configuration

**Files**:
- `lib/main.dart`

**Deliverable**: App with proper auth flow

**Estimated**: 1 hour

---

## Phase 3: Guest Experience Enhancements

### Task 3.1: Create Guest Upgrade Banner
**Objective**: Prompt guests to sign in for cloud sync

**Steps**:
1. Create `lib/presentation/widgets/guest_upgrade_banner.dart`:
   - Show only for guest users
   - Non-intrusive banner design
   - "Sign in to save progress" message
   - "Sign In" action button
2. Add to main screens (front screen, level select)
3. Implement sign-in handler with migration
4. Add dismiss/remind later functionality

**Files**:
- `lib/presentation/widgets/guest_upgrade_banner.dart` (new)
- Update screens to include banner

**Deliverable**: Guest upgrade banner

**Estimated**: 2 hours

---

### Task 3.2: Implement Guest Settings Page
**Objective**: Allow guests to manage their local account

**Steps**:
1. Update settings screen to show:
   - Guest status indicator
   - Option to change display name
   - Option to upgrade to Firebase account
   - Clear local data option
2. Add name change dialog
3. Add upgrade confirmation dialog
4. Style appropriately

**Files**:
- `lib/presentation/screens/settings/settings_screen.dart`

**Deliverable**: Guest settings UI

**Estimated**: 1.5 hours

---

### Task 3.3: Implement Data Migration Logic
**Objective**: Migrate guest progress to Firebase on sign-in

**Steps**:
1. Create `lib/data/migration/guest_to_firebase_migration.dart`:
   - Read all guest progress from SharedPreferences
   - Transform to Firestore format
   - Write to Firestore under new user ID
   - Handle conflicts (merge vs replace)
2. Implement in `HybridAuthRepository._migrateGuestDataToFirebase()`
3. Add progress indicator during migration
4. Handle migration errors gracefully
5. Clean up local data after successful migration

**Files**:
- `lib/data/migration/guest_to_firebase_migration.dart` (new)
- `lib/data/hybrid_auth_repository.dart` (update)

**Deliverable**: Working data migration

**Estimated**: 3 hours

---

## Phase 4: Testing & Polish

### Task 4.1: Write Unit Tests
**Objective**: Test guest auth components

**Steps**:
1. Test `LocalGuestAuthRepository`:
   - Guest creation
   - Guest persistence
   - Sign out
2. Test `HybridAuthRepository`:
   - Repository switching
   - Auth state management
   - Migration triggering
3. Test `User` model with guest flag
4. Achieve 80% code coverage

**Files**:
- `test/data/local/local_guest_auth_repository_test.dart` (new)
- `test/data/hybrid_auth_repository_test.dart` (new)
- `test/domain/models/user_test.dart` (update)

**Deliverable**: Comprehensive unit tests

**Estimated**: 4 hours

---

### Task 4.2: Write Integration Tests
**Objective**: Test auth flows end-to-end

**Steps**:
1. Test guest sign-in flow
2. Test Firebase sign-in flow
3. Test guest to Firebase migration
4. Test offline guest mode
5. Test sign-out and re-sign-in

**Files**:
- `integration_test/guest_auth_test.dart` (new)
- `integration_test/firebase_auth_test.dart` (update)

**Deliverable**: Integration tests

**Estimated**: 3 hours

---

### Task 4.3: Manual Testing & Bug Fixes
**Objective**: Test all scenarios and fix issues

**Steps**:
1. Test HTTPS in production
2. Test guest auth flow
3. Test Firebase auth flow
4. Test migration flow
5. Test offline mode
6. Test on multiple browsers
7. Fix any discovered bugs

**Deliverable**: Bug-free auth system

**Estimated**: 4 hours

---

### Task 4.4: Documentation
**Objective**: Document the new auth system

**Steps**:
1. Update README.md with auth info
2. Create AUTHENTICATION.md guide
3. Document HTTPS setup process
4. Document guest vs Firebase feature matrix
5. Add inline code documentation

**Files**:
- `README.md` (update)
- `AUTHENTICATION.md` (new)
- `DEPLOYMENT.md` (update with HTTPS)

**Deliverable**: Complete documentation

**Estimated**: 2 hours

---

## Summary

**Total Estimated Time**: 32.5 hours (~4-5 days)

**Critical Path**:
1. HTTPS setup (must be done first)
2. Guest auth repository
3. Hybrid repository
4. UI updates
5. Testing

**Dependencies**:
- Task 2.x depends on Task 1.4 (HTTPS working)
- Task 3.3 depends on Task 2.3 (Hybrid repository)
- Task 4.x depends on all previous tasks

**Success Criteria**:
- ✅ HTTPS working with valid certificate
- ✅ Service worker loading without errors
- ✅ Guest users can play immediately
- ✅ Firebase sign-in still works
- ✅ Guest to Firebase migration works
- ✅ 80%+ test coverage
- ✅ No console errors
