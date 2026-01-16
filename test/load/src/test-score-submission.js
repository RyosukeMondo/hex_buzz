#!/usr/bin/env node

/**
 * Load test for score submission operations
 * Tests the onScoreUpdate Cloud Function and Firestore write performance
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
    process.env.FIREBASE_AUTH_EMULATOR_HOST = `${config.emulatorHost}:${config.emulatorAuthPort}`;
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      projectId: config.firebaseProject,
    });
  }

  return admin.firestore();
}

/**
 * Create test users in Firestore
 */
async function setupTestUsers(db, count, config) {
  console.log(`\nSetting up ${count} test users...`);
  const progress = new ProgressTracker(count, 'Creating users');

  const batch = db.batch();
  const userIds = [];

  for (let i = 0; i < count; i++) {
    const userId = `${config.testData.usernamePrefix}${Date.now()}_${i}`;
    userIds.push(userId);

    const userRef = db.collection('users').doc(userId);
    batch.set(userRef, {
      uid: userId,
      displayName: `Test User ${i}`,
      email: `${userId}@loadtest.example.com`,
      photoURL: null,
      totalStars: 0,
      rank: 999999,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Commit batch every 500 documents (Firestore limit)
    if ((i + 1) % 500 === 0) {
      await batch.commit();
      progress.increment(500);
    }
  }

  // Commit remaining documents
  const remaining = count % 500;
  if (remaining > 0) {
    await batch.commit();
    progress.increment(remaining);
  }

  progress.finish();
  return userIds;
}

/**
 * Submit a score for a user
 */
async function submitScore(db, userId, config) {
  const levelId = randomItem(config.testData.levelIds);
  const stars = randomInt(config.testData.minStars, config.testData.maxStars);
  const completionTime = randomInt(
    config.testData.minCompletionTime,
    config.testData.maxCompletionTime
  );

  const submissionRef = db.collection('scoreSubmissions').doc();

  await submissionRef.set({
    userId,
    levelId,
    stars,
    time: completionTime,
    submittedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Simulate a user submitting multiple scores
 */
async function simulateUser(db, userId, config, results) {
  const numSubmissions = randomInt(1, 5);

  for (let i = 0; i < numSubmissions; i++) {
    const result = await measureTime(() => submitScore(db, userId, config));

    results.latencies.push(result.duration);

    if (result.success) {
      results.successful++;
    } else {
      results.failed++;
      results.errors.push({
        userId,
        error: result.error.message,
        timestamp: Date.now(),
      });
    }

    // Rate limiting - ensure minimum interval between submissions
    await sleep(config.rateLimit.scoreSubmission.minIntervalMs);
  }
}

/**
 * Run the load test
 */
async function runLoadTest(config) {
  console.log('\n' + '='.repeat(80));
  console.log('  Score Submission Load Test');
  console.log('='.repeat(80));
  console.log(`\nConfiguration:`);
  console.log(`  Users: ${config.users}`);
  console.log(`  Duration: ${config.duration}s`);
  console.log(`  Ramp-up: ${config.rampUp}s`);
  console.log(`  Firebase Project: ${config.firebaseProject}`);
  console.log(`  Using Emulator: ${config.useEmulator}`);

  const db = initializeFirebase(config);

  // Setup test users
  const userIds = await setupTestUsers(db, config.users, config);

  // Results tracking
  const results = {
    testName: 'score-submission',
    timestamp: new Date().toISOString(),
    configuration: config,
    latencies: [],
    successful: 0,
    failed: 0,
    errors: [],
  };

  console.log('\nStarting load test...');
  const startTime = Date.now();

  // Calculate users per batch for ramp-up
  const rampUpBatches = Math.max(1, config.rampUp);
  const usersPerBatch = Math.ceil(config.users / rampUpBatches);
  const batchDelay = (config.rampUp * 1000) / rampUpBatches;

  let activeUsers = 0;

  // Ramp up users gradually
  for (let batch = 0; batch < rampUpBatches; batch++) {
    const batchStart = batch * usersPerBatch;
    const batchEnd = Math.min((batch + 1) * usersPerBatch, config.users);
    const batchUserIds = userIds.slice(batchStart, batchEnd);

    console.log(`\nBatch ${batch + 1}/${rampUpBatches}: Starting ${batchUserIds.length} users...`);

    // Start users in this batch
    const userPromises = batchUserIds.map(userId =>
      simulateUser(db, userId, config, results)
    );

    activeUsers += batchUserIds.length;

    // Wait for ramp-up delay before next batch
    if (batch < rampUpBatches - 1) {
      await sleep(batchDelay);
    } else {
      // Last batch - wait for all users to complete
      await Promise.all(userPromises);
    }
  }

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
    config.targets.scoreSubmission
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

  // Save results to file
  if (config.reporting.saveToFile) {
    const filepath = saveResults(finalResults, config.reporting.reportDirectory);
    console.log(`Results saved to: ${filepath}`);
  }

  // Cleanup test users
  console.log('\nCleaning up test data...');
  await cleanupTestUsers(db, userIds);

  return finalResults;
}

/**
 * Cleanup test users from Firestore
 */
async function cleanupTestUsers(db, userIds) {
  const progress = new ProgressTracker(userIds.length, 'Deleting users');

  for (let i = 0; i < userIds.length; i += 500) {
    const batch = db.batch();
    const batchUserIds = userIds.slice(i, i + 500);

    for (const userId of batchUserIds) {
      batch.delete(db.collection('users').doc(userId));
      batch.delete(db.collection('leaderboard').doc(userId));
    }

    await batch.commit();
    progress.increment(batchUserIds.length);
  }

  // Also cleanup score submissions
  const submissionsSnapshot = await db
    .collection('scoreSubmissions')
    .where('userId', 'in', userIds.slice(0, 10)) // Firestore 'in' query limit is 10
    .get();

  if (!submissionsSnapshot.empty) {
    const batch = db.batch();
    submissionsSnapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
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
      default: defaultConfig.defaultUsers,
    })
    .option('duration', {
      alias: 'd',
      type: 'number',
      description: 'Test duration in seconds',
      default: defaultConfig.defaultDuration,
    })
    .option('ramp-up', {
      alias: 'r',
      type: 'number',
      description: 'Ramp-up time in seconds',
      default: defaultConfig.defaultRampUp,
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
    process.exit(1);
  }
}

main();
