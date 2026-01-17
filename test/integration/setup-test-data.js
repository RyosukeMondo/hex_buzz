#!/usr/bin/env node
/**
 * Test Data Setup Script
 *
 * Sets up test data in Firebase for integration testing including:
 * - Test users with varying scores
 * - Leaderboard entries
 * - Daily challenge data
 * - Test notifications
 *
 * Usage:
 *   node setup-test-data.js [--emulator] [--project PROJECT_ID]
 */

const admin = require('firebase-admin');
const { program } = require('commander');

// Parse command line arguments
program
  .option('--emulator', 'Use Firebase Emulator', false)
  .option('--project <project>', 'Firebase project ID', 'demo-test')
  .option('--users <count>', 'Number of test users to create', '10')
  .parse(process.argv);

const options = program.opts();

// Initialize Firebase Admin SDK
if (options.emulator) {
  console.log('Using Firebase Emulator...');
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
}

admin.initializeApp({
  projectId: options.project,
});

const db = admin.firestore();
const auth = admin.auth();

// Test user data
const TEST_USERS = [
  { username: 'TestPlayer1', email: 'test1@example.com', totalStars: 450 },
  { username: 'TestPlayer2', email: 'test2@example.com', totalStars: 380 },
  { username: 'TestPlayer3', email: 'test3@example.com', totalStars: 520 },
  { username: 'TestPlayer4', email: 'test4@example.com', totalStars: 290 },
  { username: 'TestPlayer5', email: 'test5@example.com', totalStars: 610 },
  { username: 'TestPlayer6', email: 'test6@example.com', totalStars: 340 },
  { username: 'TestPlayer7', email: 'test7@example.com', totalStars: 480 },
  { username: 'TestPlayer8', email: 'test8@example.com', totalStars: 270 },
  { username: 'TestPlayer9', email: 'test9@example.com', totalStars: 550 },
  { username: 'TestPlayer10', email: 'test10@example.com', totalStars: 420 },
];

// Helper function to create test user
async function createTestUser(userData) {
  try {
    // Create auth user (in emulator only)
    let uid;
    if (options.emulator) {
      const userRecord = await auth.createUser({
        email: userData.email,
        password: 'test123456',
        displayName: userData.username,
      });
      uid = userRecord.uid;
      console.log(`  Created auth user: ${userData.username} (${uid})`);
    } else {
      // In production/staging, use predictable test UIDs
      uid = `test_user_${userData.email.split('@')[0]}`;
    }

    // Create Firestore user document
    await db.collection('users').doc(uid).set({
      uid: uid,
      username: userData.username,
      email: userData.email,
      displayName: userData.username,
      totalStars: userData.totalStars,
      isGuest: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  Created user document: ${userData.username}`);

    return { uid, ...userData };
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log(`  User already exists: ${userData.username}`);
      // Get existing user
      const userRecord = await auth.getUserByEmail(userData.email);
      return { uid: userRecord.uid, ...userData };
    } else {
      console.error(`  Error creating user ${userData.username}:`, error.message);
      throw error;
    }
  }
}

// Create leaderboard entries
async function createLeaderboardEntries(users) {
  console.log('\nCreating leaderboard entries...');

  // Sort users by total stars (descending)
  const sortedUsers = [...users].sort((a, b) => b.totalStars - a.totalStars);

  const batch = db.batch();

  sortedUsers.forEach((user, index) => {
    const rank = index + 1;
    const leaderboardRef = db.collection('leaderboard').doc(user.uid);

    batch.set(leaderboardRef, {
      userId: user.uid,
      username: user.username,
      avatarUrl: null,
      totalStars: user.totalStars,
      rank: rank,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  Rank ${rank}: ${user.username} (${user.totalStars} stars)`);
  });

  await batch.commit();
  console.log('Leaderboard entries created successfully');
}

// Create daily challenge
async function createDailyChallenge() {
  console.log('\nCreating daily challenge...');

  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  // Simple level data for testing
  const testLevel = {
    id: `daily_${today}`,
    size: 4,
    checkpoints: [
      { q: 0, r: 0, order: 0 },
      { q: 1, r: 0, order: 1 },
      { q: 0, r: 1, order: 2 },
      { q: 1, r: 1, order: 3 },
    ],
    solution: [
      { q: 0, r: 0 },
      { q: 1, r: 0 },
      { q: 1, r: 1 },
      { q: 0, r: 1 },
    ],
  };

  await db.collection('dailyChallenges').doc(today).set({
    id: today,
    date: admin.firestore.FieldValue.serverTimestamp(),
    level: testLevel,
    completionCount: 0,
  });

  console.log(`  Daily challenge created for ${today}`);

  // Create some daily challenge completions
  console.log('\nCreating daily challenge completions...');

  const challengeCompletions = [
    { userId: 'test_user_test1', stars: 3, time: 45000, rank: 1 },
    { userId: 'test_user_test3', stars: 3, time: 52000, rank: 2 },
    { userId: 'test_user_test5', stars: 3, time: 58000, rank: 3 },
    { userId: 'test_user_test2', stars: 2, time: 67000, rank: 4 },
    { userId: 'test_user_test7', stars: 2, time: 71000, rank: 5 },
  ];

  const batch = db.batch();

  challengeCompletions.forEach((completion) => {
    const completionRef = db
      .collection('dailyChallenges')
      .doc(today)
      .collection('entries')
      .doc(completion.userId);

    batch.set(completionRef, {
      userId: completion.userId,
      stars: completion.stars,
      completionTime: completion.time,
      rank: completion.rank,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  ${completion.rank}. User ${completion.userId}: ${completion.stars} stars in ${completion.time}ms`);
  });

  await batch.commit();
  console.log('Daily challenge completions created successfully');
}

// Create score submissions
async function createScoreSubmissions(users) {
  console.log('\nCreating score submissions...');

  const batch = db.batch();

  users.slice(0, 3).forEach((user, index) => {
    const submissionRef = db.collection('scoreSubmissions').doc();

    batch.set(submissionRef, {
      userId: user.uid,
      levelId: `level_4x4_${index}`,
      stars: Math.floor(Math.random() * 3) + 1,
      completionTime: Math.floor(Math.random() * 60000) + 30000,
      moves: Math.floor(Math.random() * 20) + 10,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  Score submission for ${user.username}`);
  });

  await batch.commit();
  console.log('Score submissions created successfully');
}

// Clean up existing test data
async function cleanupTestData() {
  console.log('Cleaning up existing test data...');

  try {
    // Delete test users from auth (emulator only)
    if (options.emulator) {
      const listUsersResult = await auth.listUsers();
      const testUsers = listUsersResult.users.filter(u =>
        u.email && u.email.includes('test') && u.email.includes('@example.com')
      );

      for (const user of testUsers) {
        await auth.deleteUser(user.uid);
        console.log(`  Deleted auth user: ${user.email}`);
      }
    }

    // Delete Firestore collections
    const collections = ['users', 'leaderboard', 'scoreSubmissions'];

    for (const collectionName of collections) {
      const snapshot = await db.collection(collectionName).get();

      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        console.log(`  Deleted ${snapshot.size} documents from ${collectionName}`);
      }
    }

    // Delete daily challenges
    const today = new Date().toISOString().split('T')[0];
    const challengeRef = db.collection('dailyChallenges').doc(today);

    // Delete challenge entries subcollection
    const entriesSnapshot = await challengeRef.collection('entries').get();
    if (!entriesSnapshot.empty) {
      const batch = db.batch();
      entriesSnapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      console.log(`  Deleted ${entriesSnapshot.size} challenge entries`);
    }

    // Delete challenge document
    await challengeRef.delete();
    console.log(`  Deleted daily challenge for ${today}`);

    console.log('Cleanup completed successfully');
  } catch (error) {
    console.log('Cleanup completed with some errors (may be first run)');
  }
}

// Main setup function
async function setupTestData() {
  console.log('===========================================');
  console.log('HexBuzz Test Data Setup');
  console.log('===========================================');
  console.log(`Project: ${options.project}`);
  console.log(`Emulator: ${options.emulator ? 'Yes' : 'No'}`);
  console.log(`Test Users: ${options.users}`);
  console.log('===========================================\n');

  try {
    // Clean up existing data
    await cleanupTestData();

    console.log('\n===========================================');
    console.log('Creating new test data...');
    console.log('===========================================\n');

    // Create test users
    console.log('Creating test users...');
    const userCount = parseInt(options.users, 10);
    const usersToCreate = TEST_USERS.slice(0, userCount);
    const createdUsers = [];

    for (const userData of usersToCreate) {
      const user = await createTestUser(userData);
      createdUsers.push(user);
    }

    // Create leaderboard entries
    await createLeaderboardEntries(createdUsers);

    // Create daily challenge
    await createDailyChallenge();

    // Create score submissions
    await createScoreSubmissions(createdUsers);

    console.log('\n===========================================');
    console.log('✅ Test data setup completed successfully!');
    console.log('===========================================\n');

    console.log('Test User Credentials (password: test123456):');
    createdUsers.forEach((user, index) => {
      console.log(`  ${index + 1}. ${user.email} - ${user.username}`);
    });

    console.log('\nYou can now run integration tests with this test data.');

  } catch (error) {
    console.error('\n❌ Error setting up test data:', error);
    process.exit(1);
  } finally {
    // Clean up
    await admin.app().delete();
  }
}

// Run setup
setupTestData();
