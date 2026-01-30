# Track 5: Cloud Functions Modularization

**Status:** ready
**Priority:** medium
**Parent Spec:** `../spec.md`
**Effort:** Medium (4-6 hours)
**Risk:** Low

## Objective

Improve Cloud Functions structure, add comprehensive error handling, and eliminate code duplication.

## Problem Statement

Current Cloud Functions have several issues:
1. **Lack of comprehensive error handling** - Some endpoints don't catch all errors
2. **Code duplication** - Utility functions duplicated across files
3. **Limited logging** - Not all operations logged
4. **No request validation** - Inputs not validated consistently
5. **Monolithic structure** - Functions could be better modularized

## Current Structure

```
functions/
├── src/
│   ├── index.ts (355 lines) - Entry point + scheduled functions
│   ├── dailyChallengeGenerator.ts (182 lines)
│   ├── sendDailyChallengeNotification.ts (124 lines)
│   ├── levelGenerator.ts (298 lines)
│   ├── diagnostics.ts (168 lines)
│   ├── testClientFlow.ts (95 lines)
│   └── testLeaderboard.ts (150 lines)
└── package.json
```

## Target Structure

```
functions/
├── src/
│   ├── index.ts (150 lines) - Entry point only
│   ├── functions/
│   │   ├── dailyChallenge.ts (100 lines)
│   │   ├── notifications.ts (80 lines)
│   │   ├── leaderboard.ts (90 lines)
│   │   └── diagnostics.ts (120 lines)
│   ├── services/
│   │   ├── levelGenerator.ts (200 lines)
│   │   ├── notificationService.ts (100 lines)
│   │   └── firestoreService.ts (150 lines)
│   ├── utils/
│   │   ├── logger.ts (80 lines)
│   │   ├── validator.ts (60 lines)
│   │   ├── errorHandler.ts (100 lines)
│   │   └── dateUtils.ts (40 lines)
│   └── types/
│       ├── challenge.ts (50 lines)
│       ├── notification.ts (40 lines)
│       └── leaderboard.ts (40 lines)
└── package.json
```

## Implementation Tasks

### Task 1: Create Utilities Module

#### Logger
```typescript
// src/utils/logger.ts
import * as functions from 'firebase-functions';

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARNING = 'warning',
  ERROR = 'error',
}

export class Logger {
  static log(
    level: LogLevel,
    event: string,
    data?: Record<string, any>,
    error?: Error
  ): void {
    const logData = {
      timestamp: new Date().toISOString(),
      event,
      ...data,
    };

    switch (level) {
      case LogLevel.DEBUG:
        console.log('[DEBUG]', logData);
        break;
      case LogLevel.INFO:
        functions.logger.info(event, logData);
        break;
      case LogLevel.WARNING:
        functions.logger.warn(event, logData);
        break;
      case LogLevel.ERROR:
        functions.logger.error(event, { ...logData, error: error?.message, stack: error?.stack });
        break;
    }
  }

  static info(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.INFO, event, data);
  }

  static error(event: string, error: Error, data?: Record<string, any>): void {
    this.log(LogLevel.ERROR, event, data, error);
  }

  static warn(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.WARNING, event, data);
  }

  static debug(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, event, data);
  }
}
```

#### Error Handler
```typescript
// src/utils/errorHandler.ts
import { Logger } from './logger';
import { HttpsError } from 'firebase-functions/v2/https';

export class ErrorHandler {
  static handle(error: Error, context: string): never {
    Logger.error('function_error', error, { context });

    if (error instanceof HttpsError) {
      throw error;
    }

    // Convert to HttpsError for consistent client handling
    if (error.message.includes('not found')) {
      throw new HttpsError('not-found', error.message);
    }

    if (error.message.includes('unauthorized')) {
      throw new HttpsError('unauthenticated', error.message);
    }

    if (error.message.includes('permission')) {
      throw new HttpsError('permission-denied', error.message);
    }

    // Default to internal error
    throw new HttpsError('internal', 'An unexpected error occurred', {
      original: error.message,
    });
  }

  static async wrap<T>(
    fn: () => Promise<T>,
    context: string
  ): Promise<T> {
    try {
      return await fn();
    } catch (error) {
      this.handle(error as Error, context);
    }
  }
}
```

#### Validator
```typescript
// src/utils/validator.ts
import { HttpsError } from 'firebase-functions/v2/https';

export class Validator {
  static required(value: any, field: string): void {
    if (value === undefined || value === null || value === '') {
      throw new HttpsError('invalid-argument', `${field} is required`);
    }
  }

  static isString(value: any, field: string): void {
    if (typeof value !== 'string') {
      throw new HttpsError('invalid-argument', `${field} must be a string`);
    }
  }

  static isNumber(value: any, field: string): void {
    if (typeof value !== 'number' || isNaN(value)) {
      throw new HttpsError('invalid-argument', `${field} must be a number`);
    }
  }

  static isPositive(value: number, field: string): void {
    if (value <= 0) {
      throw new HttpsError('invalid-argument', `${field} must be positive`);
    }
  }

  static inRange(value: number, min: number, max: number, field: string): void {
    if (value < min || value > max) {
      throw new HttpsError(
        'invalid-argument',
        `${field} must be between ${min} and ${max}`
      );
    }
  }

  static isValidDate(date: string, field: string): void {
    const parsed = Date.parse(date);
    if (isNaN(parsed)) {
      throw new HttpsError('invalid-argument', `${field} must be a valid date`);
    }
  }
}
```

### Task 2: Create Service Layer

#### Firestore Service
```typescript
// src/services/firestoreService.ts
import { getFirestore } from 'firebase-admin/firestore';
import { Logger } from '../utils/logger';
import { ErrorHandler } from '../utils/errorHandler';

export class FirestoreService {
  private db = getFirestore();

  async getDocument<T>(collection: string, docId: string): Promise<T | null> {
    return ErrorHandler.wrap(async () => {
      Logger.debug('firestore_read', { collection, docId });

      const doc = await this.db.collection(collection).doc(docId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as T;
    }, 'getDocument');
  }

  async setDocument<T>(
    collection: string,
    docId: string,
    data: T
  ): Promise<void> {
    return ErrorHandler.wrap(async () => {
      Logger.debug('firestore_write', { collection, docId });
      await this.db.collection(collection).doc(docId).set(data);
    }, 'setDocument');
  }

  async updateDocument<T>(
    collection: string,
    docId: string,
    data: Partial<T>
  ): Promise<void> {
    return ErrorHandler.wrap(async () => {
      Logger.debug('firestore_update', { collection, docId });
      await this.db.collection(collection).doc(docId).update(data);
    }, 'updateDocument');
  }

  async queryCollection<T>(
    collection: string,
    filters: Array<{ field: string; op: any; value: any }>
  ): Promise<T[]> {
    return ErrorHandler.wrap(async () => {
      Logger.debug('firestore_query', { collection, filters });

      let query: any = this.db.collection(collection);

      for (const filter of filters) {
        query = query.where(filter.field, filter.op, filter.value);
      }

      const snapshot = await query.get();
      return snapshot.docs.map((doc: any) => doc.data() as T);
    }, 'queryCollection');
  }
}
```

### Task 3: Extract Function Modules

#### Daily Challenge Function
```typescript
// src/functions/dailyChallenge.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall } from 'firebase-functions/v2/https';
import { LevelGeneratorService } from '../services/levelGenerator';
import { FirestoreService } from '../services/firestoreService';
import { NotificationService } from '../services/notificationService';
import { Logger } from '../utils/logger';
import { ErrorHandler } from '../utils/errorHandler';

const levelGenerator = new LevelGeneratorService();
const firestore = new FirestoreService();
const notifications = new NotificationService();

export const generateDailyChallenge = onSchedule(
  { schedule: '0 0 * * *', timeZone: 'UTC' },
  async (event) => {
    return ErrorHandler.wrap(async () => {
      const today = new Date().toISOString().split('T')[0];

      Logger.info('daily_challenge_generation_started', { date: today });

      // Check if challenge already exists
      const existing = await firestore.getDocument('dailyChallenges', today);
      if (existing) {
        Logger.info('daily_challenge_already_exists', { date: today });
        return;
      }

      // Generate new challenge
      const level = await levelGenerator.generateChallenge({ difficulty: 'medium' });

      // Save to Firestore
      await firestore.setDocument('dailyChallenges', today, {
        id: today,
        createdAt: new Date().toISOString(),
        level,
        completionCount: 0,
        notificationSent: false,
      });

      Logger.info('daily_challenge_generated', { date: today, levelId: level.id });

      // Send notifications
      await notifications.sendDailyChallengeNotification(today);

      return { success: true, date: today };
    }, 'generateDailyChallenge');
  }
);

export const getDailyChallenge = onCall(async (request) => {
  return ErrorHandler.wrap(async () => {
    const date = request.data.date || new Date().toISOString().split('T')[0];

    Logger.info('daily_challenge_requested', { date, userId: request.auth?.uid });

    const challenge = await firestore.getDocument('dailyChallenges', date);

    if (!challenge) {
      throw new Error('Challenge not found for date: ' + date);
    }

    return challenge;
  }, 'getDailyChallenge');
});
```

### Task 4: Add Comprehensive Error Handling

Wrap all function exports:
```typescript
// ✅ Pattern for all functions
export const myFunction = onCall(async (request) => {
  return ErrorHandler.wrap(async () => {
    // Validate input
    Validator.required(request.data.param, 'param');

    // Log start
    Logger.info('my_function_started', { param: request.data.param });

    // Business logic
    const result = await doSomething(request.data.param);

    // Log success
    Logger.info('my_function_completed', { result });

    return result;
  }, 'myFunction');
});
```

### Task 5: Add Request Validation

Validate all inputs:
```typescript
export const submitScore = onCall(async (request) => {
  return ErrorHandler.wrap(async () => {
    const { levelId, score, timeMs } = request.data;

    // Validate
    Validator.required(levelId, 'levelId');
    Validator.isString(levelId, 'levelId');
    Validator.required(score, 'score');
    Validator.isNumber(score, 'score');
    Validator.inRange(score, 0, 3, 'score');
    Validator.required(timeMs, 'timeMs');
    Validator.isNumber(timeMs, 'timeMs');
    Validator.isPositive(timeMs, 'timeMs');

    // Check auth
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Process
    // ...
  }, 'submitScore');
});
```

### Task 6: Add TypeScript Types

Create strong types:
```typescript
// src/types/challenge.ts
export interface DailyChallenge {
  id: string;
  createdAt: string;
  level: Level;
  completionCount: number;
  notificationSent: boolean;
}

export interface Level {
  id: string;
  gridSize: number;
  difficulty: 'easy' | 'medium' | 'hard';
  cells: HexCell[];
  startPosition: HexCoordinate;
  endPosition: HexCoordinate;
  checkpoints?: HexCoordinate[];
}

export interface HexCell {
  q: number;
  r: number;
  type: CellType;
}

export type CellType = 'normal' | 'start' | 'end' | 'checkpoint' | 'blocked';

export interface HexCoordinate {
  q: number;
  r: number;
}
```

### Task 7: Add Comprehensive Tests

Test all utilities:
```typescript
// functions/test/utils/validator.test.ts
import { Validator } from '../../src/utils/validator';

describe('Validator', () => {
  describe('required', () => {
    it('throws for undefined', () => {
      expect(() => Validator.required(undefined, 'field'))
        .toThrow('field is required');
    });

    it('does not throw for valid value', () => {
      expect(() => Validator.required('value', 'field')).not.toThrow();
    });
  });

  describe('isNumber', () => {
    it('throws for string', () => {
      expect(() => Validator.isNumber('123', 'field'))
        .toThrow('field must be a number');
    });

    it('does not throw for number', () => {
      expect(() => Validator.isNumber(123, 'field')).not.toThrow();
    });
  });
});
```

## Success Criteria

- [ ] All functions have comprehensive error handling
- [ ] All inputs validated
- [ ] All operations logged
- [ ] No code duplication
- [ ] Proper modular structure
- [ ] All functions have tests
- [ ] Test coverage ≥70%
- [ ] All existing functionality works

## Testing Strategy

### Unit Tests
- Test all utilities (logger, validator, error handler)
- Test all services in isolation
- Mock Firestore and external dependencies

### Integration Tests
- Test functions end-to-end
- Use Firebase Functions test framework
- Test error scenarios

## Dependencies

- `firebase-functions` v2 (existing)
- `firebase-admin` (existing)
- `jest` (existing)
- TypeScript (existing)

## Completion Checklist

- [ ] Task 1: Utilities module created
- [ ] Task 2: Service layer created
- [ ] Task 3: Functions modularized
- [ ] Task 4: Error handling added
- [ ] Task 5: Request validation added
- [ ] Task 6: TypeScript types added
- [ ] Task 7: Tests added
- [ ] All functions refactored
- [ ] All tests pass
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- Utilities: 1 hour
- Services: 1.5 hours
- Function refactoring: 2 hours
- Error handling: 1 hour
- Validation: 1 hour
- Types: 30 minutes
- Tests: 2 hours
- Review: 1 hour

**Total: 4-6 hours**
