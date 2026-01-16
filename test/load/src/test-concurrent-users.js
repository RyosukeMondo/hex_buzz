#!/usr/bin/env node

/**
 * Load test simulating concurrent users with mixed operations
 * Tests realistic user behavior patterns and system stability
 */

import admin from 'firebase-admin';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { defaultConfig, mergeConfig } from './config.js';
import {
  calculateStats,
  randomInt,
  randomItem,
  sleep,
  saveResults,
  printResultsSummary,
  ProgressTracker,
  measureTime,
} from './utils.js';

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase(config) {
  if (config.useEmulator) {
    process.env.FIRESTORE_EMULATOR_HOST = `${config.emulatorHost}:${config.emulatorFirestorePort}`;
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      projectId: config.firebaseProject,
    });
  }

  return admin.firestore();
}

/**
 * Setup initial test data
 */
async function setupTestData(db, config) {
  console.log('\nSetting up test data...');

  const userCount = config.users;
  const leaderboardSize = Math.max(userCount * 2, 1000);

  const progress = new ProgressTracker(userCount + leaderboardSize, 'Creating test data');

  // Create test users
  const userIds = [];
  for (let i = 0; i < userCount; i += 500) {
    const batch = db.batch();
    const batchEnd = Math.min(i + 500, userCount);

    for (let j = i; j < batchEnd; j++) {
      const userId = `${config.testData.usernamePrefix}${Date.now()}_${j}`;
      userIds.push(userId);

      batch.set(db.collection('users').doc(userId), {
        uid: userId,
        displayName: `Test User ${j}`,
        email: `${userId}@loadtest.example.com`,
        totalStars: randomInt(0, 500),
        rank: 999999,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    progress.increment(batchEnd - i);
  }

  // Create leaderboard entries
  for (let i = 0; i < leaderboardSize; i += 500) {
    const batch = db.batch();
    const batchEnd = Math.min(i + 500, leaderboardSize);

    for (let j = i; j < batchEnd; j++) {
      const userId = j < userCount ? userIds[j] : `lb_user_${j}`;

      batch.set(db.collection('leaderboard').doc(userId), {
        userId,
        username: `User ${j}`,
        avatarUrl: null,
        totalStars: randomInt(0, 1000),
        rank: j + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    progress.increment(batchEnd - i);
  }

  // Create daily challenge
  const dateStr = new Date().toISOString().split('T')[0];
  await db.collection('dailyChallenges').doc(dateStr).set({
    id: dateStr,
    date: admin.firestore.Timestamp.now(),
    levelId: 15,
    level: {
      id: 15,
      size: 8,
      checkpoints: 5,
      difficulty: 'medium',
    },
    completionCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  progress.finish();
  return { userIds, dateStr };
}

/**
 * Simulate realistic user session with mixed operations
 */
async function simulateUserSession(db, userId, dateStr, duration, config, results) {
  const endTime = Date.now() + duration * 1000;
  const operations = [];

  while (Date.now() < endTime) {
    // Weighted random operation selection (realistic user behavior)
    const rand = Math.random();
    let operation;

    if (rand < 0.4) {
      // 40% - Query leaderboard
      operation = 'query_leaderboard';
    } else if (rand < 0.7) {
      // 30% - Submit score
      operation = 'submit_score';
    } else if (rand < 0.85) {
      // 15% - View daily challenge
      operation = 'view_daily_challenge';
    } else {
      // 15% - Complete daily challenge
      operation = 'complete_daily_challenge';
    }

    operations.push(operation);

    // Execute operation
    let result;

    switch (operation) {
      case 'query_leaderboard':
        result = await measureTime(async () => {
          const limit = 50;
          const offset = randomInt(0, 3) * limit;
          return await db
            .collection('leaderboard')
            .orderBy('totalStars', 'desc')
            .orderBy('updatedAt', 'asc')
            .limit(limit)
            .offset(offset)
            .get();
        });
        break;

      case 'submit_score':
        result = await measureTime(async () => {
          const levelId = randomItem(config.testData.levelIds);
          const stars = randomInt(1, 3);
          const time = randomInt(10000, 180000);

          await db.collection('scoreSubmissions').add({
            userId,
            levelId,
            stars,
            time,
            submittedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        await sleep(1000); // Rate limiting
        break;

      case 'view_daily_challenge':
        result = await measureTime(async () => {
          return await db
            .collection('dailyChallenges')
            .doc(dateStr)
            .get();
        });
        break;

      case 'complete_daily_challenge':
        result = await measureTime(async () => {
          const stars = randomInt(1, 3);
          const completionTime = randomInt(15000, 200000);

          const challengeRef = db.collection('dailyChallenges').doc(dateStr);
          const completionRef = challengeRef.collection('completions').doc(userId);

          const batch = db.batch();
          batch.set(completionRef, {
            userId,
            stars,
            completionTimeMs: completionTime,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          batch.update(challengeRef, {
            completionCount: admin.firestore.FieldValue.increment(1),
          });

          await batch.commit();
        });
        break;
    }

    // Record results
    results.latencies.push(result.duration);
    results.operationLatencies[operation].push(result.duration);

    if (result.success) {
      results.successful++;
      results.operationCounts[operation].success++;
    } else {
      results.failed++;
      results.operationCounts[operation].failed++;
      results.errors.push({
        userId,
        operation,
        error: result.error?.message || 'Unknown error',
        timestamp: Date.now(),
      });
    }

    // Simulate user think time (1-5 seconds)
    await sleep(randomInt(1000, 5000));
  }
}

/**
 * Run the load test
 */
async function runLoadTest(config) {
  console.log('\n' + '='.repeat(80));
  console.log('  Concurrent Users Load Test (Mixed Operations)');
  console.log('='.repeat(80));
  console.log(`\nConfiguration:`);
  console.log(`  Users: ${config.users}`);
  console.log(`  Duration: ${config.duration}s`);
  console.log(`  Ramp-up: ${config.rampUp}s`);
  console.log(`  Firebase Project: ${config.firebaseProject}`);
  console.log(`  Using Emulator: ${config.useEmulator}`);

  const db = initializeFirebase(config);

  // Setup test data
  const { userIds, dateStr } = await setupTestData(db, config);

  // Results tracking
  const results = {
    testName: 'concurrent-users',
    timestamp: new Date().toISOString(),
    configuration: config,
    latencies: [],
    successful: 0,
    failed: 0,
    errors: [],
    operationCounts: {
      query_leaderboard: { success: 0, failed: 0 },
      submit_score: { success: 0, failed: 0 },
      view_daily_challenge: { success: 0, failed: 0 },
      complete_daily_challenge: { success: 0, failed: 0 },
    },
    operationLatencies: {
      query_leaderboard: [],
      submit_score: [],
      view_daily_challenge: [],
      complete_daily_challenge: [],
    },
  };

  console.log('\nStarting load test...');
  const startTime = Date.now();

  // Ramp up users gradually
  const rampUpBatches = Math.max(1, Math.floor(config.rampUp / 5));
  const usersPerBatch = Math.ceil(config.users / rampUpBatches);
  const batchDelay = (config.rampUp * 1000) / rampUpBatches;

  const allUserPromises = [];

  for (let batch = 0; batch < rampUpBatches; batch++) {
    const batchStart = batch * usersPerBatch;
    const batchEnd = Math.min((batch + 1) * usersPerBatch, config.users);
    const batchUserIds = userIds.slice(batchStart, batchEnd);

    console.log(`\nBatch ${batch + 1}/${rampUpBatches}: Starting ${batchUserIds.length} users...`);

    // Start users in this batch
    const batchPromises = batchUserIds.map(userId =>
      simulateUserSession(db, userId, dateStr, config.duration, config, results)
    );

    allUserPromises.push(...batchPromises);

    // Wait for ramp-up delay before next batch
    if (batch < rampUpBatches - 1) {
      await sleep(batchDelay);
    }
  }

  // Wait for all users to complete
  console.log('\nAll users started, waiting for sessions to complete...');
  await Promise.all(allUserPromises);

  const endTime = Date.now();
  const actualDuration = (endTime - startTime) / 1000;

  console.log('\n\nLoad test completed!');

  // Calculate statistics
  const latencyStats = calculateStats(results.latencies);
  const totalOperations = results.successful + results.failed;
  const errorRate = totalOperations > 0 ? results.failed / totalOperations : 0;

  // Calculate per-operation statistics
  const operationStats = {};
  for (const [operation, latencies] of Object.entries(results.operationLatencies)) {
    operationStats[operation] = calculateStats(latencies);
  }

  // Compile final results
  const finalResults = {
    ...results,
    duration: actualDuration,
    totalOperations,
    successfulOperations: results.successful,
    failedOperations: results.failed,
    throughput: totalOperations / actualDuration,
    latencyStats,
    operationStats,
    sloValidation: {
      passed: errorRate < 0.05 && latencyStats.p95 < 5000,
      violations: [],
    },
  };

  // Print summary
  printResultsSummary(finalResults);

  console.log('\nOperation Breakdown:');
  for (const [operation, counts] of Object.entries(results.operationCounts)) {
    const total = counts.success + counts.failed;
    const percentage = ((total / totalOperations) * 100).toFixed(1);
    const stats = operationStats[operation];

    console.log(`\n  ${operation}:`);
    console.log(`    Count: ${total} (${percentage}%)`);
    console.log(`    Success: ${counts.success}`);
    console.log(`    Failed: ${counts.failed}`);
    console.log(`    Mean Latency: ${stats.mean.toFixed(2)}ms`);
    console.log(`    P95 Latency: ${stats.p95.toFixed(2)}ms`);
  }

  // Save results to file
  if (config.reporting.saveToFile) {
    const filepath = saveResults(finalResults, config.reporting.reportDirectory);
    console.log(`\nResults saved to: ${filepath}`);
  }

  // Cleanup test data
  console.log('\nCleaning up test data...');
  await cleanupTestData(db, userIds, dateStr);

  return finalResults;
}

/**
 * Cleanup test data from Firestore
 */
async function cleanupTestData(db, userIds, dateStr) {
  const progress = new ProgressTracker(userIds.length + 1, 'Cleaning up');

  // Delete users and leaderboard entries
  for (let i = 0; i < userIds.length; i += 500) {
    const batch = db.batch();
    const batchEnd = Math.min(i + 500, userIds.length);

    for (let j = i; j < batchEnd; j++) {
      batch.delete(db.collection('users').doc(userIds[j]));
      batch.delete(db.collection('leaderboard').doc(userIds[j]));
    }

    await batch.commit();
    progress.increment(batchEnd - i);
  }

  // Delete daily challenge and completions
  const challengeRef = db.collection('dailyChallenges').doc(dateStr);
  const completionsSnapshot = await challengeRef.collection('completions').get();

  if (!completionsSnapshot.empty) {
    const batch = db.batch();
    completionsSnapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }

  await challengeRef.delete();
  progress.increment(1);

  progress.finish();
}

/**
 * Parse command-line arguments and run test
 */
async function main() {
  const argv = yargs(hideBin(process.argv))
    .option('users', {
      alias: 'u',
      type: 'number',
      description: 'Number of concurrent users',
      default: 1000,
    })
    .option('duration', {
      alias: 'd',
      type: 'number',
      description: 'Test duration in seconds',
      default: 300,
    })
    .option('ramp-up', {
      alias: 'r',
      type: 'number',
      description: 'Ramp-up time in seconds',
      default: 30,
    })
    .option('firebase-project', {
      alias: 'p',
      type: 'string',
      description: 'Firebase project ID',
      default: defaultConfig.firebaseProject,
    })
    .option('emulator', {
      alias: 'e',
      type: 'boolean',
      description: 'Use Firebase Emulator',
      default: defaultConfig.useEmulator,
    })
    .option('verbose', {
      alias: 'v',
      type: 'boolean',
      description: 'Enable verbose logging',
      default: false,
    })
    .help()
    .argv;

  const config = mergeConfig({
    users: argv.users,
    duration: argv.duration,
    rampUp: argv['ramp-up'],
    firebaseProject: argv['firebase-project'],
    useEmulator: argv.emulator,
    reporting: {
      ...defaultConfig.reporting,
      enableVerboseLogging: argv.verbose,
    },
  });

  try {
    await runLoadTest(config);
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Load test failed:', error);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
