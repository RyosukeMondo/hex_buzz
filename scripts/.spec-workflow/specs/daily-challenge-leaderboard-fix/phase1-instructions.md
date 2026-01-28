# Phase 1: Data Population - Instructions

## Status
Scripts created ✅
Needs Firebase authentication ⚠️

## Quick Start

### Step 1: Login to Firebase CLI
```bash
firebase login
```

This will open a browser for authentication. Login with your Google account that has access to the hexbuzz-game Firebase project.

### Step 2: Run the population script
```bash
cd /home/rmondo/repos/hex_buzz
node scripts/populate_firestore_data.js
```

This script will:
- Create today's daily challenge in Firestore
- Add 10 test users to the leaderboard with various star counts

### Step 3: Verify data in Firebase Console
1. Go to https://console.firebase.google.com/
2. Select "hexbuzz-game" project
3. Go to Firestore Database
4. Check for:
   - `dailyChallenges` collection with today's date document
   - `leaderboard` collection with 10 test user documents

### Step 4: Test the app
1. Go to https://mondo-ai-studio.xvps.jp/hex_buzz/
2. Click "Daily Challenge" - should show today's challenge (not infinite loading)
3. Click "Leaderboard" - should show 10 test users ranked by stars

## Troubleshooting

### Error: "No authorized accounts"
Run `firebase login` first

### Error: "Permission denied"
Make sure your Google account has Firestore access in the Firebase project

### Error: "Project not found"
Update the project ID in `scripts/populate_firestore_data.js` line 9

### Still seeing infinite loading
1. Hard refresh browser (Ctrl+Shift+R)
2. Check browser console for errors
3. Verify data exists in Firebase Console

## Next Steps

After Phase 1 is complete:
- **Phase 2**: Setup Cloud Functions for automated daily challenge generation
- **Phase 3**: Add push notifications for new challenges
- **Phase 4**: Optimize leaderboard performance
- **Phase 5**: Add E2E tests

## Files Created

- `scripts/populate_firestore_data.js` - Node.js script to populate Firestore
- `scripts/package.json` - npm dependencies (firebase-admin)
