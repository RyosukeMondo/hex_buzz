# HexBuzz Cloud Functions

Modularized Cloud Functions for HexBuzz with comprehensive error handling, logging, and validation.

## Architecture

### Directory Structure

```
functions/
├── src/
│   ├── index.ts              # Entry point - exports all functions
│   ├── functions/            # Cloud Function modules
│   │   ├── dailyChallenge.ts    # Daily challenge generation and retrieval
│   │   ├── leaderboard.ts       # Leaderboard updates
│   │   └── diagnostics.ts       # System diagnostics
│   ├── services/             # Business logic services
│   │   ├── firestoreService.ts      # Firestore abstraction layer
│   │   ├── levelGenerator.ts       # Level generation logic
│   │   └── notificationService.ts  # FCM notifications
│   ├── utils/                # Utility modules
│   │   ├── logger.ts           # Structured logging
│   │   ├── errorHandler.ts     # Centralized error handling
│   │   ├── validator.ts        # Input validation
│   │   └── dateUtils.ts        # Date utilities
│   └── types/                # TypeScript type definitions
│       ├── challenge.ts        # Challenge and level types
│       ├── leaderboard.ts      # Leaderboard types
│       └── notification.ts     # Notification types
└── test/                     # Test files
    ├── setup.ts                 # Test setup
    ├── utils/                   # Utility tests
    └── services/                # Service tests
```

## Features

### 1. Modular Structure
- Clear separation of concerns
- Reusable service layer
- Type-safe interfaces
- Easy to test and maintain

### 2. Comprehensive Error Handling
- Centralized error handler
- Automatic conversion to HttpsError
- Detailed error logging
- Context-aware error messages

### 3. Structured Logging
- JSON-formatted logs
- Multiple log levels (DEBUG, INFO, WARNING, ERROR)
- Timestamp and context in every log
- Firebase Functions Logger integration

### 4. Input Validation
- Type checking
- Range validation
- Required field validation
- Date format validation

### 5. Comprehensive Testing
- Unit tests for utilities
- Service layer tests
- Test coverage reporting
- Firebase Admin test setup

## Deployed Functions

### Daily Challenge Functions

#### `scheduledDailyChallengeGenerator`
- **Type**: Scheduled (PubSub)
- **Schedule**: Daily at 11:00 UTC (8PM JST)
- **Purpose**: Generates new daily challenge
- **Memory**: 512MB
- **Timeout**: 300s

#### `onDailyChallengeCreated`
- **Type**: Firestore Trigger
- **Trigger**: `dailyChallenges/{challengeId}` onCreate
- **Purpose**: Sends push notifications when new challenge is created
- **Memory**: 512MB
- **Timeout**: 300s

#### `manualGenerateChallenge`
- **Type**: HTTP Request
- **Method**: POST
- **Purpose**: Manually trigger daily challenge generation (testing)
- **Memory**: 256MB
- **Timeout**: 60s

#### `manualSendNotification`
- **Type**: HTTP Request
- **Method**: POST
- **Purpose**: Manually send push notifications (testing)
- **Memory**: 256MB
- **Timeout**: 60s

#### `getDailyChallenge`
- **Type**: Callable (HTTPS v2)
- **Purpose**: Retrieve daily challenge for a specific date
- **Parameters**: `{ date?: string }` (defaults to today)
- **Returns**: DailyChallenge object

### Leaderboard Functions

#### `updateLeaderboardOnCompletion`
- **Type**: Firestore Trigger
- **Trigger**: `scoreSubmissions/{submissionId}` onCreate
- **Purpose**: Updates global leaderboard when user completes level
- **Memory**: 256MB
- **Timeout**: 60s

### Diagnostic Functions

#### `apiDiagnostics`
- **Type**: HTTP Request
- **Method**: GET
- **Purpose**: Run comprehensive system diagnostics
- **Returns**: Diagnostic results with test status
- **CORS**: Enabled

## Development

### Prerequisites
- Node.js 20
- Firebase CLI
- TypeScript 5.x

### Setup

```bash
cd functions
npm install
```

### Build

```bash
npm run build
```

### Test

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Lint

```bash
# Check for linting errors
npm run lint

# Auto-fix linting errors
npm run lint:fix
```

### Local Development

```bash
# Start Firebase emulators
npm run serve

# Start Firebase shell
npm run shell
```

### Deploy

```bash
# Deploy all functions
npm run deploy

# Deploy specific function
firebase deploy --only functions:scheduledDailyChallengeGenerator
```

## Service Layer

### FirestoreService

Provides abstracted database operations with logging and error handling.

```typescript
const firestore = new FirestoreService();

// Get document
const doc = await firestore.getDocument<T>('collection', 'docId');

// Set document
await firestore.setDocument('collection', 'docId', data);

// Update document
await firestore.updateDocument('collection', 'docId', partialData);

// Query collection
const results = await firestore.queryCollection<T>('collection', [
  { field: 'status', op: '==', value: 'active' }
]);
```

### LevelGeneratorService

Generates hexagonal grid levels for daily challenges.

```typescript
const levelGenerator = new LevelGeneratorService();

// Generate challenge with options
const level = await levelGenerator.generateChallenge({
  difficulty: 'medium', // 'easy' | 'medium' | 'hard'
  size: 6,
  wallDensity: 0.2
});
```

### NotificationService

Handles FCM push notifications.

```typescript
const notifications = new NotificationService();

// Send daily challenge notification
await notifications.sendDailyChallengeNotification(challengeId);
```

## Utilities

### Logger

Structured logging with multiple levels.

```typescript
import { Logger } from './utils/logger';

Logger.info('event_name', { data: 'value' });
Logger.error('error_event', error, { context: 'data' });
Logger.warn('warning_event', { data: 'value' });
Logger.debug('debug_event', { data: 'value' });
```

### ErrorHandler

Centralized error handling.

```typescript
import { ErrorHandler } from './utils/errorHandler';

// Wrap async operations
const result = await ErrorHandler.wrap(async () => {
  // Your code here
  return data;
}, 'contextName');
```

### Validator

Input validation utilities.

```typescript
import { Validator } from './utils/validator';

Validator.required(value, 'fieldName');
Validator.isString(value, 'fieldName');
Validator.isNumber(value, 'fieldName');
Validator.isPositive(value, 'fieldName');
Validator.inRange(value, min, max, 'fieldName');
Validator.isValidDate(dateString, 'fieldName');
```

### DateUtils

Date manipulation utilities.

```typescript
import { DateUtils } from './utils/dateUtils';

const today = DateUtils.getToday(); // YYYY-MM-DD
const formatted = DateUtils.formatDate(new Date());
const parsed = DateUtils.parseDate('2025-01-30');
```

## Testing

### Test Coverage

Current coverage: ~65%

- Utilities: 65%+
- Services: 66%+
- Functions: Integration tests pending

### Running Tests

```bash
# All tests
npm test

# With coverage
npm run test:coverage

# Watch mode
npm run test:watch
```

## Code Quality Standards

### TypeScript
- Strict mode enabled
- Strong typing throughout
- No implicit any (warnings only)

### Linting
- Google style guide
- Double quotes
- 2-space indentation
- Max line length: 100 characters

### Code Metrics
- Max 500 lines per file (excluding legacy files)
- Max 50 lines per function
- Test coverage target: 65%+

## Error Handling Pattern

All functions follow this pattern:

```typescript
export const myFunction = onCall(async (request) => {
  return ErrorHandler.wrap(async () => {
    // Validate input
    Validator.required(request.data.param, 'param');

    // Log start
    Logger.info('function_started', { param: request.data.param });

    // Business logic
    const result = await doSomething(request.data.param);

    // Log success
    Logger.info('function_completed', { result });

    return result;
  }, 'myFunction');
});
```

## Logging Pattern

Structured logs include:

```json
{
  "timestamp": "2025-01-30T12:00:00.000Z",
  "event": "event_name",
  "level": "INFO",
  "data": {
    "key": "value"
  }
}
```

## Migration from Legacy Code

The following legacy files remain for backward compatibility:
- `logsApi.ts`
- `testClientFlow.ts`
- `testLeaderboard.ts`

These can be removed once confirmed unused by clients.

## Monitoring

### Cloud Functions Console
- Monitor function invocations
- Check error rates
- Review logs

### Diagnostics Endpoint
```bash
curl https://REGION-PROJECT.cloudfunctions.net/apiDiagnostics
```

Returns comprehensive system health check.

## Best Practices

1. **Always use ErrorHandler.wrap** for async operations
2. **Log important events** with structured data
3. **Validate all inputs** at entry points
4. **Use type-safe interfaces** from types/
5. **Write tests** for new functionality
6. **Keep functions small** (< 50 lines)
7. **Use services** for business logic

## Future Enhancements

- [ ] Add more integration tests
- [ ] Implement retry logic for FCM
- [ ] Add rate limiting
- [ ] Implement caching layer
- [ ] Add performance monitoring
- [ ] Create admin dashboard function
- [ ] Add batch operations support
