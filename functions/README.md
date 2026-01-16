# HexBuzz Cloud Functions

This directory contains Firebase Cloud Functions for HexBuzz's social and competitive features.

## Functions

### 1. onScoreUpdate (Firestore Trigger)
- **Trigger**: When a document is created in `scoreSubmissions` collection
- **Purpose**: Updates user's total stars, leaderboard rankings, and sends rank change notifications
- **Actions**:
  - Updates user's level progress and total stars
  - Updates leaderboard entry
  - Recomputes all user ranks
  - Sends notification if rank changed by ±10 or more

### 2. generateDailyChallenge (Scheduled)
- **Schedule**: Daily at 00:00 UTC
- **Purpose**: Generates a new daily challenge level
- **Actions**:
  - Selects a random level (currently levels 10-30)
  - Creates daily challenge document with date as ID (YYYY-MM-DD)
  - Triggers notification sending
  - Idempotent (won't create duplicate challenges)

### 3. sendDailyChallengeNotifications (HTTP Callable)
- **Trigger**: Manual call or after daily challenge generation
- **Purpose**: Sends push notifications to all subscribed users
- **Actions**:
  - Sends FCM topic message to "daily_challenge" topic
  - Includes deep link data to daily challenge screen

### 4. onUserCreated (Firestore Trigger)
- **Trigger**: When a new user document is created in `users` collection
- **Purpose**: Initializes new user data
- **Actions**:
  - Creates leaderboard entry with 0 stars
  - Subscribes user's device token to "daily_challenge" topic

### 5. recomputeAllRanks (HTTP Callable)
- **Trigger**: Manual call (admin/testing)
- **Purpose**: Recomputes all leaderboard ranks
- **Actions**:
  - Queries all leaderboard entries ordered by stars
  - Updates rank field for all entries in batches

## Setup

### Prerequisites
- Node.js 20+
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project configured

### Installation

```bash
npm install
```

### Build

```bash
npm run build
```

### Local Testing with Emulators

```bash
npm run serve
```

### Deploy to Firebase

```bash
npm run deploy
```

Or deploy from project root:

```bash
firebase deploy --only functions
```

## Environment Configuration

The functions use Firebase Admin SDK which initializes automatically with default credentials. For local development with emulators, set:

```bash
export FIREBASE_CONFIG='{"projectId":"your-project-id"}'
```

## Monitoring

View function logs:

```bash
npm run logs
```

Or in Firebase Console:
- Functions → Logs
- Monitor execution times, errors, and resource usage

## Testing

### Test Score Update
1. Add a document to `scoreSubmissions` collection
2. Verify user's totalStars and leaderboard entry updated
3. Check if ranks were recomputed

### Test Daily Challenge
1. Call `generateDailyChallenge` manually or wait for scheduled execution
2. Verify document created in `dailyChallenges` collection
3. Check notification sent to topic

### Test User Creation
1. Create a new user document in `users` collection
2. Verify leaderboard entry created
3. Check topic subscription (if device token provided)

## Performance Considerations

- **Rank Recomputation**: Currently recomputes ALL ranks on every score update. For large user bases (>10,000 users), consider:
  - Implementing incremental rank updates
  - Batching rank updates (e.g., every 5 minutes)
  - Using Cloud Tasks for background processing

- **Notification Limits**: FCM has rate limits. For large user bases:
  - Use topic messaging (currently implemented)
  - Consider batched sends with FCM multicast

## Security

- Functions run with Firebase Admin privileges
- HTTP callable functions require authentication
- Firestore security rules still apply for client access
- Device tokens and user data are sensitive - handle appropriately

## Cost Optimization

- Functions use Node.js 20 (latest supported version)
- Scheduled functions run once daily (minimal cost)
- Firestore triggers only on new documents (not updates)
- Consider function timeout settings for production
