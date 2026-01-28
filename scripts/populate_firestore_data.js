#!/usr/bin/env node
/**
 * Script to populate Firestore with test data for daily challenge and leaderboard.
 *
 * Usage: node scripts/populate_firestore_data.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'hexbuzz-game'
});

const db = admin.firestore();

async function main() {
  console.log('🔥 Initializing Firebase Admin...');

  console.log('\n📝 Step 1: Creating daily challenge for today...');
  await createDailyChallenge();

  console.log('\n📝 Step 2: Creating leaderboard entries...');
  await createLeaderboardEntries();

  console.log('\n✅ Done! Firestore populated successfully.');
  console.log('   - Daily challenge created for today');
  console.log('   - 10 test users added to leaderboard');
  console.log('\n🚀 You can now test the app!');

  process.exit(0);
}

/**
 * Creates today's daily challenge in Firestore.
 */
async function createDailyChallenge() {
  const today = new Date();
  const dateStr = formatDate(today);

  console.log(`   Creating challenge for date: ${dateStr}`);

  // Generate a simple 6x6 level
  const level = generateLevel(6, 'medium');

  const challengeRef = db.collection('dailyChallenges').doc(dateStr);

  // Check if already exists
  const existingDoc = await challengeRef.get();
  if (existingDoc.exists) {
    console.log('   ⚠️  Challenge already exists for today, skipping...');
    return;
  }

  await challengeRef.set({
    id: dateStr,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    level: level,
    completionCount: 0,
    notificationSent: false
  });

  console.log('   ✓ Daily challenge created successfully');
}

/**
 * Creates test leaderboard entries.
 */
async function createLeaderboardEntries() {
  const testUsers = [
    { username: 'BeeKeeper', stars: 245 },
    { username: 'HoneyHunter', stars: 198 },
    { username: 'BuzzMaster', stars: 187 },
    { username: 'HiveQueen', stars: 165 },
    { username: 'PollenCollector', stars: 142 },
    { username: 'NectarSeeker', stars: 128 },
    { username: 'WaxWorker', stars: 115 },
    { username: 'DroneRanger', stars: 98 },
    { username: 'HoneyDipper', stars: 87 },
    { username: 'BumbleBuddy', stars: 76 }
  ];

  let count = 0;
  for (const user of testUsers) {
    const userId = `test_user_${count + 1}`;
    const leaderboardRef = db.collection('leaderboard').doc(userId);

    // Check if already exists
    const existingDoc = await leaderboardRef.get();
    if (existingDoc.exists) {
      console.log(`   ⚠️  Leaderboard entry for ${user.username} already exists, skipping...`);
      count++;
      continue;
    }

    await leaderboardRef.set({
      userId: userId,
      username: user.username,
      avatarUrl: null,
      totalStars: user.stars,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLevel: `level-${Math.floor(count / 2) + 1}`
    });

    console.log(`   ✓ Created leaderboard entry for ${user.username} (${user.stars} stars)`);
    count++;
  }

  console.log(`   ✓ ${count} leaderboard entries created`);
}

/**
 * Generates a level for daily challenge.
 */
function generateLevel(gridSize, difficulty) {
  const cells = [];

  // Generate hexagonal grid
  for (let q = 0; q < gridSize; q++) {
    for (let r = 0; r < gridSize; r++) {
      // Skip cells outside hexagonal shape
      if ((q + r) < gridSize || (q + r) >= gridSize * 2) {
        continue;
      }

      // Random 30% of cells are obstacles
      const isObstacle = Math.random() < 0.3;

      cells.push({
        q: q,
        r: r,
        isObstacle: isObstacle
      });
    }
  }

  // Ensure start and end are not obstacles
  const start = { q: 0, r: gridSize - 1, isObstacle: false };
  const end = { q: gridSize - 1, r: gridSize - 1, isObstacle: false };

  // Remove any existing cells at start/end positions
  const filteredCells = cells.filter(c => !((c.q === start.q && c.r === start.r) || (c.q === end.q && c.r === end.r)));
  filteredCells.push(start);
  filteredCells.push(end);

  return {
    id: `daily-${formatDate(new Date())}`,
    gridSize: gridSize,
    difficulty: difficulty,
    cells: filteredCells,
    startPosition: start,
    endPosition: end
  };
}

/**
 * Formats a Date as YYYY-MM-DD.
 */
function formatDate(date) {
  const year = date.getUTCFullYear().toString().padStart(4, '0');
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0');
  const day = date.getUTCDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Run main function
main().catch(console.error);
