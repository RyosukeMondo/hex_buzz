# Phase 1: Data Population - Instructions

## Status
✅ Scripts created
✅ Web-based script ready (no auth needed!)

## Quick Start (Web-based - Recommended!)

### Step 1: Open the population script in browser
```bash
cd /home/rmondo/repos/hex_buzz
firefox scripts/populate_firestore_web.html
```

Or use any browser:
```bash
google-chrome scripts/populate_firestore_web.html
# or
xdg-open scripts/populate_firestore_web.html
```

### Step 2: Click "Populate Firestore" button
The script will automatically:
- Create today's daily challenge (2026-01-27) in Firestore
- Add 10 test users to the leaderboard with various star counts (245 to 76 stars)

Watch the log output to see progress. It will show:
- 🔥 Firebase initialization
- ✓ Daily challenge creation
- ✓ Each leaderboard entry created
- ✅ Success message

### Step 3: Verify data in Firebase Console
1. Go to https://console.firebase.google.com/
2. Select "hexbuzz-game" project
3. Go to Firestore Database
4. Check for:
   - `dailyChallenges/2026-01-27` document
   - `leaderboard` collection with 10 test user documents

### Step 4: Test the app
1. Go to https://mondo-ai-studio.xvps.jp/hex_buzz/
2. Click "Daily Challenge" - should show today's challenge (not infinite loading!)
3. Click "Leaderboard" - should show 10 test users ranked by stars

## Alternative: Node.js Script (Requires Service Account)

If you prefer Node.js, you need to set up Application Default Credentials:

### Step 1: Download service account key
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save the JSON file to your machine

### Step 2: Set environment variable
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

### Step 3: Run the script
```bash
cd /home/rmondo/repos/hex_buzz
node scripts/populate_firestore_data.js
```

## Troubleshooting

### Web script: "Failed to load resource" or CORS error
This is expected - Firebase Web SDK works fine even with console errors. Check the log output on the page for actual success/failure.

### Web script: "Permission denied"
Make sure Firestore security rules allow writes. You may need to temporarily set:
```
allow read, write: if true;
```
(Remember to restore proper rules after testing!)

### Still seeing infinite loading in app
1. Hard refresh browser (Ctrl+Shift+R)
2. Check browser console for errors
3. Verify data exists in Firebase Console
4. Check network tab - is Firestore request returning data?

### Script says "already exists"
That's fine! It means data was already populated. You can proceed to testing.

## Files Created

- `scripts/populate_firestore_web.html` - ✅ Web-based script (RECOMMENDED)
- `scripts/populate_firestore_data.js` - Node.js script (requires auth)
- `scripts/package.json` - npm dependencies

## What the scripts create

### Daily Challenge Document
```
dailyChallenges/2026-01-27:
  - id: "2026-01-27"
  - level: { 6x6 hex grid with obstacles }
  - completionCount: 0
  - createdAt: <timestamp>
```

### Leaderboard Entries (10 users)
```
leaderboard/test_user_1:
  - username: "BeeKeeper"
  - totalStars: 245
  - updatedAt: <timestamp>

... (9 more users with decreasing star counts)
```

## Next Steps After Phase 1

Once you verify data is showing in the app:
- **Phase 2**: Setup Cloud Functions for automated daily challenge generation
- **Phase 3**: Add push notifications for new challenges
- **Phase 4**: Optimize leaderboard performance
- **Phase 5**: Add E2E tests
