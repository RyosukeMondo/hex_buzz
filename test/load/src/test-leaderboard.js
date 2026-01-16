#!/usr/bin/env node

/**
 * Load test for leaderboard query operations
 * Tests Firestore query performance with concurrent reads
 */

import admin from 'firebase-admin';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { defaultConfig, mergeConfig } from './config.js';
import {
  calculateStats,
  randomInt,
  sleep,
  saveResults,
  printResultsSummary,
  validateSLOs,
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
 * Create test leaderboard data
 */
async function setupTestLeaderboard(db, userCount, config) {
  console.log(`\nSetting up leaderboard with ${userCount} users...`);
  const progress = new ProgressTracker(userCount, 'Creating leaderboard entries');

  const batch = db.batch();
  const userIds = [];

  for (let i = 0; i < userCount; i++) {
    const userId = `${config.testData.usernamePrefix}${Date.now()}_${i}`;
    userIds.push(userId);

    const leaderboardRef = db.collection('leaderboard').doc(userId);
    batch.set(leaderboardRef, {
      userId,
      username: `Test User ${i}`,
      avatarUrl: null,
      totalStars: randomInt(0, 1000),
      rank: i + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 500 === 0) {
      await batch.commit();
      progress.increment(500);
    }
  }

  const remaining = userCount % 500;
  if (remaining > 0) {
    await batch.commit();
    progress.increment(remaining);
  }

  progress.finish();
  return userIds;
}

/**
 * Query leaderboard top players
 */
async function queryLeaderboard(db, limit = 50, offset = 0) {
  const query = db
    .collection('leaderboard')
    .orderBy('totalStars', 'desc')
    .orderBy('updatedAt', 'asc')
    .limit(limit);

  let snapshot;
  if (offset > 0) {
    const skipSnapshot = await db
      .collection('leaderboard')
      .orderBy('totalStars', 'desc')
      .orderBy('updatedAt', 'asc')
      .limit(offset)
      .get();

    if (skipSnapshot.docs.length > 0) {
      snapshot = await query.startAfterDocument(skipSnapshot.docs[skipSnapshot.docs.length - 1]).get();
    } else {
      snapshot = await query.get();
    }
  } else {
    snapshot = await query.get();
  }

  return snapshot.docs.map(doc => doc.data());
}

/**
 * Get user's rank from leaderboard
 */
async function getUserRank(db, userId) {
  const userDoc = await db.collection('leaderboard').doc(userId).get();

  if (!userDoc.exists) {
    throw new Error('User not found in leaderboard');
  }

  const userData = userDoc.data();
  const userStars = userData.totalStars || 0;

  // Count users with more stars
  const higherRankCount = await db
    .collection('leaderboard')
    .where('totalStars', '>', userStars)
    .count()
    .get();

  const rank = higherRankCount.data().count + 1;

  return {
    ...userData,
    rank,
  };
}

/**
 * Simulate a user querying the leaderboard
 */
async function simulateUser(db, userId, queriesPerUser, results) {
  for (let i = 0; i < queriesPerUser; i++) {
    // Randomly choose operation type
    const operationType = Math.random() < 0.7 ? 'top_players' : 'user_rank';

    let result;

    if (operationType === 'top_players') {
      // Query top players with random pagination
      const limit = 50;
      const offset = randomInt(0, 5) * limit;
      result = await measureTime(() => queryLeaderboard(db, limit, offset));
    } else {
      // Query user's own rank
      result = await measureTime(() => getUserRank(db, userId));
    }

    results.latencies.push(result.duration);

    if (result.success) {
      results.successful++;
      results.operationCounts[operationType]++;
    } else {
      results.failed++;
      results.errors.push({
        userId,
        operationType,
        error: result.error.message,
        timestamp: Date.now(),
      });
    }

    // Rate limiting
    await sleep(100); // Small delay between queries
  }
}

/**
 * Run the load test
 */
async function runLoadTest(config) {
  console.log('\n' + '='.repeat(80));
  console.log('  Leaderboard Query Load Test');
  console.log('='.repeat(80));
  console.log(`\nConfiguration:`);
  console.log(`  Users: ${config.users}`);
  console.log(`  Queries per user: ${config.queriesPerUser}`);
  console.log(`  Firebase Project: ${config.firebaseProject}`);
  console.log(`  Using Emulator: ${config.useEmulator}`);

  const db = initializeFirebase(config);

  // Setup test leaderboard (need more users than concurrent users for realistic queries)
  const leaderboardSize = Math.max(config.users * 2, 1000);
  const userIds = await setupTestLeaderboard(db, leaderboardSize, config);

  // Results tracking
  const results = {
    testName: 'leaderboard-query',
    timestamp: new Date().toISOString(),
    configuration: config,
    latencies: [],
    successful: 0,
    failed: 0,
    errors: [],
    operationCounts: {
      top_players: 0,
      user_rank: 0,
    },
  };

  console.log('\nStarting load test...');
  const startTime = Date.now();

  // Select random users to simulate queries
  const testUserIds = [];
  for (let i = 0; i < config.users; i++) {
    testUserIds.push(userIds[randomInt(0, userIds.length - 1)]);
  }

  // Run concurrent user simulations
  const userPromises = testUserIds.map(userId =>
    simulateUser(db, userId, config.queriesPerUser, results)
  );

  await Promise.all(userPromises);

  const endTime = Date.now();
  const actualDuration = (endTime - startTime) / 1000;

  console.log('\n\nLoad test completed!');

  // Calculate statistics
  const latencyStats = calculateStats(results.latencies);
  const totalOperations = results.successful + results.failed;
  const errorRate = totalOperations > 0 ? results.failed / totalOperations : 0;

  // Validate against SLOs
  const sloValidation = validateSLOs(
    {
      ...latencyStats,
      errorRate,
    },
    config.targets.leaderboardQuery
  );

  // Compile final results
  const finalResults = {
    ...results,
    duration: actualDuration,
    totalOperations,
    successfulOperations: results.successful,
    failedOperations: results.failed,
    throughput: totalOperations / actualDuration,
    latencyStats,
    sloValidation,
  };

  // Print summary
  printResultsSummary(finalResults);

  console.log('\nOperation Breakdown:');
  console.log(`  Top Players Queries: ${results.operationCounts.top_players}`);
  console.log(`  User Rank Queries: ${results.operationCounts.user_rank}`);

  // Save results to file
  if (config.reporting.saveToFile) {
    const filepath = saveResults(finalResults, config.reporting.reportDirectory);
    console.log(`\nResults saved to: ${filepath}`);
  }

  // Cleanup test data
  console.log('\nCleaning up test data...');
  await cleanupTestData(db, userIds);

  return finalResults;
}

/**
 * Cleanup test data from Firestore
 */
async function cleanupTestData(db, userIds) {
  const progress = new ProgressTracker(userIds.length, 'Deleting leaderboard entries');

  for (let i = 0; i < userIds.length; i += 500) {
    const batch = db.batch();
    const batchUserIds = userIds.slice(i, i + 500);

    for (const userId of batchUserIds) {
      batch.delete(db.collection('leaderboard').doc(userId));
    }

    await batch.commit();
    progress.increment(batchUserIds.length);
  }

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
      default: 500,
    })
    .option('queries-per-user', {
      alias: 'q',
      type: 'number',
      description: 'Number of queries per user',
      default: 10,
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
    queriesPerUser: argv['queries-per-user'],
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
    process.exit(1);
  }
}

main();
