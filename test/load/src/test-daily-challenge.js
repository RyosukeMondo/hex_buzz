#!/usr/bin/env node

/**
 * Load test for daily challenge operations
 * Tests daily challenge generation and concurrent completions
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
 * Generate a daily challenge
 */
async function generateDailyChallenge(db, dateStr) {
  const levelId = randomInt(10, 30);

  const challengeRef = db.collection('dailyChallenges').doc(dateStr);

  await challengeRef.set({
    id: dateStr,
    date: admin.firestore.Timestamp.now(),
    levelId,
    level: {
      id: levelId,
      size: 6 + Math.floor(levelId / 5),
      checkpoints: randomInt(3, 8),
      difficulty: levelId < 15 ? 'easy' : levelId < 25 ? 'medium' : 'hard',
    },
    completionCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return levelId;
}

/**
 * Submit a challenge completion
 */
async function submitChallengeCompletion(db, dateStr, userId, stars, completionTimeMs) {
  const challengeRef = db.collection('dailyChallenges').doc(dateStr);
  const completionRef = challengeRef.collection('completions').doc(userId);

  const batch = db.batch();

  // Check if completion already exists
  const existingCompletion = await completionRef.get();

  if (existingCompletion.exists) {
    const existingData = existingCompletion.data();
    const existingStars = existingData.stars || 0;
    const existingTime = existingData.completionTimeMs || 0;

    // Only update if better score
    if (stars > existingStars || (stars === existingStars && completionTimeMs < existingTime)) {
      batch.update(completionRef, {
        stars,
        completionTimeMs,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } else {
    // First completion
    batch.set(completionRef, {
      userId,
      stars,
      completionTimeMs,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment completion count
    batch.update(challengeRef, {
      completionCount: admin.firestore.FieldValue.increment(1),
    });
  }

  await batch.commit();
}

/**
 * Query daily challenge leaderboard
 */
async function getChallengeLeaderboard(db, dateStr, limit = 50) {
  const challengeRef = db.collection('dailyChallenges').doc(dateStr);
  const completionsSnapshot = await challengeRef
    .collection('completions')
    .orderBy('stars', 'desc')
    .orderBy('completionTimeMs', 'asc')
    .limit(limit)
    .get();

  return completionsSnapshot.docs.map((doc, index) => ({
    ...doc.data(),
    rank: index + 1,
  }));
}

/**
 * Simulate a user completing the daily challenge
 */
async function simulateUser(db, dateStr, userId, config, results) {
  // User completes the challenge
  const stars = randomInt(config.testData.minStars, config.testData.maxStars);
  const completionTime = randomInt(
    config.testData.minCompletionTime,
    config.testData.maxCompletionTime
  );

  const submissionResult = await measureTime(() =>
    submitChallengeCompletion(db, dateStr, userId, stars, completionTime)
  );

  results.latencies.push(submissionResult.duration);

  if (submissionResult.success) {
    results.successful++;
  } else {
    results.failed++;
    results.errors.push({
      userId,
      operation: 'submit_completion',
      error: submissionResult.error.message,
      timestamp: Date.now(),
    });
  }

  // Random chance to view leaderboard after completion
  if (Math.random() < 0.5) {
    await sleep(randomInt(500, 2000)); // Think time

    const leaderboardResult = await measureTime(() =>
      getChallengeLeaderboard(db, dateStr, 50)
    );

    results.latencies.push(leaderboardResult.duration);

    if (leaderboardResult.success) {
      results.successful++;
      results.leaderboardQueries++;
    } else {
      results.failed++;
      results.errors.push({
        userId,
        operation: 'query_leaderboard',
        error: leaderboardResult.error.message,
        timestamp: Date.now(),
      });
    }
  }
}

/**
 * Run the load test
 */
async function runLoadTest(config) {
  console.log('\n' + '='.repeat(80));
  console.log('  Daily Challenge Load Test');
  console.log('='.repeat(80));
  console.log(`\nConfiguration:`);
  console.log(`  Users: ${config.users}`);
  console.log(`  Concurrent: ${config.concurrent}`);
  console.log(`  Firebase Project: ${config.firebaseProject}`);
  console.log(`  Using Emulator: ${config.useEmulator}`);

  const db = initializeFirebase(config);

  // Generate today's challenge
  const dateStr = new Date().toISOString().split('T')[0];
  console.log(`\nGenerating daily challenge for ${dateStr}...`);

  const generationResult = await measureTime(() =>
    generateDailyChallenge(db, dateStr)
  );

  if (!generationResult.success) {
    throw new Error(`Failed to generate daily challenge: ${generationResult.error.message}`);
  }

  console.log(`✓ Challenge generated (${generationResult.duration}ms)`);

  // Create test user IDs
  const userIds = Array.from(
    { length: config.users },
    (_, i) => `${config.testData.usernamePrefix}${Date.now()}_${i}`
  );

  // Results tracking
  const results = {
    testName: 'daily-challenge',
    timestamp: new Date().toISOString(),
    configuration: config,
    challengeGenerationTime: generationResult.duration,
    latencies: [],
    successful: 0,
    failed: 0,
    errors: [],
    leaderboardQueries: 0,
  };

  console.log('\nStarting load test...');
  console.log(`Simulating ${config.users} users completing the challenge...`);
  const startTime = Date.now();

  // Run users in batches to control concurrency
  const batchSize = config.concurrent;
  const batches = Math.ceil(config.users / batchSize);

  for (let batch = 0; batch < batches; batch++) {
    const batchStart = batch * batchSize;
    const batchEnd = Math.min((batch + 1) * batchSize, config.users);
    const batchUserIds = userIds.slice(batchStart, batchEnd);

    console.log(`Batch ${batch + 1}/${batches}: ${batchUserIds.length} users`);

    const batchPromises = batchUserIds.map(userId =>
      simulateUser(db, dateStr, userId, config, results)
    );

    await Promise.all(batchPromises);
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
    config.targets.dailyChallenge
  );

  // Get final challenge stats
  const challengeDoc = await db.collection('dailyChallenges').doc(dateStr).get();
  const challengeData = challengeDoc.data();

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
    finalChallengeStats: {
      completionCount: challengeData?.completionCount || 0,
      leaderboardQueries: results.leaderboardQueries,
    },
  };

  // Print summary
  printResultsSummary(finalResults);

  console.log('\nDaily Challenge Stats:');
  console.log(`  Challenge Generation Time: ${generationResult.duration}ms`);
  console.log(`  Total Completions: ${finalResults.finalChallengeStats.completionCount}`);
  console.log(`  Leaderboard Queries: ${finalResults.finalChallengeStats.leaderboardQueries}`);

  // Save results to file
  if (config.reporting.saveToFile) {
    const filepath = saveResults(finalResults, config.reporting.reportDirectory);
    console.log(`\nResults saved to: ${filepath}`);
  }

  // Cleanup test data
  console.log('\nCleaning up test data...');
  await cleanupTestData(db, dateStr);

  return finalResults;
}

/**
 * Cleanup test data from Firestore
 */
async function cleanupTestData(db, dateStr) {
  console.log('Deleting challenge and completions...');

  const challengeRef = db.collection('dailyChallenges').doc(dateStr);

  // Delete all completions
  const completionsSnapshot = await challengeRef.collection('completions').get();
  const batch = db.batch();

  completionsSnapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  // Delete challenge document
  await challengeRef.delete();

  console.log('✓ Cleanup complete');
}

/**
 * Parse command-line arguments and run test
 */
async function main() {
  const argv = yargs(hideBin(process.argv))
    .option('users', {
      alias: 'u',
      type: 'number',
      description: 'Number of users',
      default: 800,
    })
    .option('concurrent', {
      alias: 'c',
      type: 'number',
      description: 'Concurrent users per batch',
      default: 100,
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
    concurrent: argv.concurrent,
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
