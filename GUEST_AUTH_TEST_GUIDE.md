# 🧪 Guest Authentication Test Guide

## ✅ Implementation Complete

Your HexBuzz app now has **hybrid authentication** supporting both guest and Firebase users!

### 🌐 Live URL
**https://mondo-ai-studio.xvps.jp/hex_buzz**

---

## 🎮 Testing Guest Authentication

### Test 1: Guest Login Flow

1. **Open the app**
   - Navigate to: https://mondo-ai-studio.xvps.jp/hex_buzz
   - You should see the auth screen

2. **Click "Play as Guest"**
   - Look for the button with play icon
   - Click it

3. **Expected behavior:**
   - ✅ Instantly logged in (no Firebase needed)
   - ✅ Redirected to level selection
   - ✅ Can start playing immediately
   - ✅ Progress saved locally

4. **Verify guest ID**
   - Open browser DevTools (F12)
   - Go to Application → Local Storage
   - Look for `guest_user_id` key
   - Should see a UUID like: `f47ac10b-58cc-4372-a567-0e02b2c3d479`

### Test 2: Guest Data Persistence

1. **Play some levels as guest**
   - Complete a few levels
   - Note your progress

2. **Refresh the page** (F5)
   - Expected: Still logged in as guest
   - Expected: Progress preserved

3. **Close and reopen browser**
   - Navigate back to the app
   - Expected: Still logged in as same guest
   - Expected: Same guest ID
   - Expected: Progress still there

### Test 3: Offline Functionality

1. **Log in as guest**
2. **Open DevTools → Network tab**
3. **Enable "Offline" mode**
4. **Try playing**
   - Expected: Game still works
   - Expected: Progress still saves locally
   - Expected: No errors

---

## 🔐 Testing Firebase Authentication

### Test 4: Google Sign-In Flow

1. **Open the app in new incognito window**
   - Ensures clean state

2. **Click "Sign in with Google"**
   - Should open Google OAuth screen

3. **Complete Google Sign-In**
   - Expected: Successfully logged in
   - Expected: Redirected to levels
   - Expected: Can see your Google profile info

4. **Check Firestore**
   - Go to Firebase Console
   - Check Firestore → users collection
   - Should see your user document

### Test 5: Guest to Firebase Migration

1. **Open app as guest**
   - Play some levels
   - Complete a few

2. **Sign in with Google**
   - Click "Sign in with Google"
   - Complete OAuth flow

3. **Expected behavior:**
   - ✅ Successfully signed in with Google
   - ✅ Guest session cleared
   - ✅ Now using Firebase account
   - Note: Full data migration is TODO (see below)

---

## 🔍 What to Look For

### Success Indicators

**Guest Login:**
- [ ] No Firebase network requests during guest login
- [ ] Instant login (< 100ms)
- [ ] Guest ID stored in localStorage
- [ ] Can play offline
- [ ] Progress saved locally

**Firebase Login:**
- [ ] Google OAuth screen appears
- [ ] Firestore user document created
- [ ] Can see user profile info
- [ ] Progress synced to cloud

### Common Issues

**Issue**: Guest login shows error
- **Solution**: Check browser console for errors
- **Check**: Is localStorage enabled?
- **Check**: Are cookies enabled?

**Issue**: Firebase login fails
- **Solution**: Check Firebase configuration
- **Check**: Is domain authorized in Firebase Console?
- **Check**: Check browser console for specific error

**Issue**: Service worker errors
- **Solution**: Should be fixed with HTTPS
- **Check**: Is URL using https:// ?

---

## 📊 Monitoring & Debugging

### Check Guest Data (Browser DevTools)

```javascript
// Open console and run:
localStorage.getItem('guest_user_id')
localStorage.getItem('guest_display_name')
localStorage.getItem('guest_created_at')
```

### Check Network Requests

1. Open DevTools → Network tab
2. Guest login: Should see NO Firebase requests
3. Google Sign-In: Should see Google OAuth + Firebase requests

### Check Auth State

In browser console:
```javascript
// See current auth state in app
// (implementation-specific, may need to expose debug info)
```

---

## 🚧 Known TODOs

### Data Migration (Not Yet Implemented)

When a guest upgrades to Firebase, data migration is currently minimal:

**What happens now:**
- Guest session cleared
- Firebase account created
- Guest progress NOT migrated

**TODO: Implement full migration**
Location: `lib/data/hybrid_auth_repository.dart:161`

```dart
Future<void> _migrateGuestDataToFirebase(
  domain.User guestUser,
  domain.User firebaseUser,
) async {
  // TODO: Implement data migration
  // - Copy level progress from local to Firestore
  // - Copy achievements
  // - Copy statistics
  // - Clean up local data
}
```

**How to implement:**
1. Read guest progress from LocalProgressRepository
2. Write to Firestore for Firebase user
3. Update user document with stats
4. Clear local guest data

---

## 🎯 User Flow Diagram

```
┌─────────────────────────────────────────────┐
│         App Starts                          │
│   (Check for existing auth)                 │
└─────────────┬───────────────────────────────┘
              │
              ▼
    ┌─────────────────┐
    │ Has Guest ID?   │──── Yes ────→ Continue as Guest
    └────────┬────────┘
             │ No
             ▼
    ┌─────────────────┐
    │Has Firebase Auth│──── Yes ────→ Continue with Firebase
    └────────┬────────┘
             │ No
             ▼
    ┌─────────────────────────────────┐
    │     Auth Screen                 │
    │  ┌──────────────────────────┐  │
    │  │  Sign in with Google     │──→ Firebase Flow
    │  └──────────────────────────┘  │
    │                                 │
    │  ┌──────────────────────────┐  │
    │  │    Play as Guest         │──→ Guest Flow
    │  └──────────────────────────┘  │
    └─────────────────────────────────┘
```

---

## 📝 Files Modified/Created

### New Files
- `lib/data/local/local_guest_auth_repository.dart`
- `lib/data/hybrid_auth_repository.dart`
- `GUEST_AUTH_TEST_GUIDE.md` (this file)

### Modified Files
- `lib/main.dart` (added hybrid repo initialization)
- `pubspec.yaml` (added uuid dependency)

### Unchanged (Already Ready)
- `lib/presentation/screens/auth/auth_screen.dart`
- `lib/presentation/providers/auth_provider.dart`
- `lib/domain/models/user.dart`

---

## 🎉 Summary

Your app now supports:
- ✅ Instant guest access (no registration)
- ✅ Offline play for guests
- ✅ Google Sign-In for Firebase
- ✅ Local progress storage for guests
- ✅ Cloud sync for Firebase users
- ⏳ Guest → Firebase migration (basic, needs enhancement)

**Test it now:** https://mondo-ai-studio.xvps.jp/hex_buzz

Try both authentication methods and verify everything works as expected!
