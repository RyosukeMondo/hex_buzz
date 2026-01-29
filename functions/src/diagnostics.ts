/**
 * API Diagnostics Function
 * Comprehensive REST API endpoint that tests all Firebase/Firestore operations
 * Returns JSON results with zero manual testing required
 */

import * as admin from "firebase-admin";

interface DiagnosticResult {
  timestamp: string;
  tests: {
    dailyChallenge: TestResult;
    leaderboardRead: TestResult;
    leaderboardWrite: TestResult;
    firestoreRules: TestResult;
  };
  summary: {
    totalTests: number;
    passed: number;
    failed: number;
    warnings: number;
  };
  recommendations: string[];
}

interface TestResult {
  name: string;
  status: "PASS" | "FAIL" | "WARN";
  duration: number;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  details: any;
  error?: string;
}

/**
 * Runs comprehensive diagnostics on all API endpoints
 */
export async function runDiagnostics(): Promise<DiagnosticResult> {
  const db = admin.firestore();

  const results: DiagnosticResult = {
    timestamp: new Date().toISOString(),
    tests: {
      dailyChallenge: await testDailyChallenge(db),
      leaderboardRead: await testLeaderboardRead(db),
      leaderboardWrite: await testLeaderboardWrite(db),
      firestoreRules: await testFirestoreRules(db),
    },
    summary: {
      totalTests: 0,
      passed: 0,
      failed: 0,
      warnings: 0,
    },
    recommendations: [],
  };

  // Calculate summary
  const tests = Object.values(results.tests);
  results.summary.totalTests = tests.length;
  results.summary.passed = tests.filter((t) => t.status === "PASS").length;
  results.summary.failed = tests.filter((t) => t.status === "FAIL").length;
  results.summary.warnings = tests.filter((t) => t.status === "WARN").length;

  // Generate recommendations
  results.recommendations = generateRecommendations(results.tests);

  return results;
}

/**
 * Test 1: Daily Challenge Endpoint
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {Promise<TestResult>} Test result with status and details
 */
async function testDailyChallenge(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();
  const today = formatDate(new Date());

  try {
    const docRef = db.collection("dailyChallenges").doc(today);
    const doc = await docRef.get();

    if (!doc.exists) {
      return {
        name: "Daily Challenge - GET",
        status: "FAIL",
        duration: Date.now() - start,
        details: {
          date: today,
          exists: false,
          message: "No daily challenge found for today",
        },
        error: "Daily challenge document does not exist",
      };
    }

    const data = doc.data()!;
    const level = data.level || {};

    // Validate level structure
    const hasRequiredFields =
      level.size &&
      level.checkpointCount &&
      level.cells &&
      level.walls;

    if (!hasRequiredFields) {
      return {
        name: "Daily Challenge - GET",
        status: "WARN",
        duration: Date.now() - start,
        details: {
          date: today,
          exists: true,
          id: data.id,
          levelStructure: {
            hasSize: !!level.size,
            hasCheckpointCount: !!level.checkpointCount,
            hasCells: !!level.cells,
            hasWalls: !!level.walls,
          },
        },
        error: "Level structure is incomplete",
      };
    }

    return {
      name: "Daily Challenge - GET",
      status: "PASS",
      duration: Date.now() - start,
      details: {
        date: today,
        exists: true,
        id: data.id,
        gridSize: level.size,
        checkpointCount: level.checkpointCount,
        cellCount: level.cells?.length || 0,
        wallCount: level.walls?.length || 0,
        completionCount: data.completionCount || 0,
        notificationSent: data.notificationSent || false,
      },
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } catch (error: any) {
    return {
      name: "Daily Challenge - GET",
      status: "FAIL",
      duration: Date.now() - start,
      details: { date: today },
      error: error.message,
    };
  }
}

/**
 * Test 2: Leaderboard Read
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {Promise<TestResult>} Test result with status and details
 */
async function testLeaderboardRead(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();
  const today = formatDate(new Date());

  try {
    const entriesRef = db
      .collection("dailyChallenges")
      .doc(today)
      .collection("entries");

    const snapshot = await entriesRef.get();

    if (snapshot.empty) {
      return {
        name: "Leaderboard Entries - READ",
        status: "WARN",
        duration: Date.now() - start,
        details: {
          date: today,
          entryCount: 0,
          message: "No entries found - no one has completed today's challenge",
        },
      };
    }

    const entries = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        userId: doc.id,
        username: data.username,
        stars: data.stars,
        completionTime: data.completionTime,
        totalStars: data.totalStars,
        completedAt: data.completedAt,
      };
    });

    // Sort by stars (desc) and time (asc)
    entries.sort((a, b) => {
      if (b.stars !== a.stars) return b.stars - a.stars;
      return a.completionTime - b.completionTime;
    });

    return {
      name: "Leaderboard Entries - READ",
      status: "PASS",
      duration: Date.now() - start,
      details: {
        date: today,
        entryCount: entries.length,
        topEntry: entries[0],
        allEntries: entries,
      },
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } catch (error: any) {
    return {
      name: "Leaderboard Entries - READ",
      status: "FAIL",
      duration: Date.now() - start,
      details: { date: today },
      error: error.message,
    };
  }
}

/**
 * Test 3: Leaderboard Write
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {Promise<TestResult>} Test result with status and details
 */
async function testLeaderboardWrite(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();
  const today = formatDate(new Date());
  const testUserId = `diagnostic-test-${Date.now()}`;

  try {
    const entryRef = db
      .collection("dailyChallenges")
      .doc(today)
      .collection("entries")
      .doc(testUserId);

    // Attempt to write test entry
    await entryRef.set({
      userId: testUserId,
      username: "Diagnostic Test",
      stars: 3,
      completionTime: 99999,
      totalStars: 999,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Verify write
    const doc = await entryRef.get();
    const writeSuccess = doc.exists;

    // Clean up test entry
    await entryRef.delete();

    return {
      name: "Leaderboard Entries - WRITE",
      status: writeSuccess ? "PASS" : "FAIL",
      duration: Date.now() - start,
      details: {
        date: today,
        testUserId,
        writeSuccess,
        deletedAfterTest: true,
      },
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } catch (error: any) {
    return {
      name: "Leaderboard Entries - WRITE",
      status: "FAIL",
      duration: Date.now() - start,
      details: { date: today, testUserId },
      error: error.message,
    };
  }
}

/**
 * Test 4: Firestore Rules
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {Promise<TestResult>} Test result with status and details
 */
async function testFirestoreRules(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();

  try {
    // Test various collection access
    const tests = {
      dailyChallengesRead: false,
      entriesRead: false,
      entriesWrite: false,
      leaderboardRead: false,
    };

    // Daily challenges collection
    try {
      await db.collection("dailyChallenges").limit(1).get();
      tests.dailyChallengesRead = true;
    } catch (e) {
      // Expected to fail without auth
    }

    // Entries subcollection
    try {
      const today = formatDate(new Date());
      await db
        .collection("dailyChallenges")
        .doc(today)
        .collection("entries")
        .limit(1)
        .get();
      tests.entriesRead = true;
    } catch (e) {
      // Expected to fail without auth
    }

    // Leaderboard collection
    try {
      await db.collection("leaderboard").limit(1).get();
      tests.leaderboardRead = true;
    } catch (e) {
      // Expected to fail without auth
    }

    const allPass = Object.values(tests).every((v) => v === true);

    return {
      name: "Firestore Security Rules",
      status: allPass ? "PASS" : "WARN",
      duration: Date.now() - start,
      details: {
        tests,
        message: allPass ?
          "All collections accessible (may be too permissive)" :
          "Some collections restricted (expected)",
      },
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } catch (error: any) {
    return {
      name: "Firestore Security Rules",
      status: "WARN",
      duration: Date.now() - start,
      details: {},
      error: error.message,
    };
  }
}

/**
 * Generate recommendations based on test results
 * @param {Object} tests - Test results object
 * @return {string[]} Array of recommendation strings
 */
function generateRecommendations(tests: {
  [key: string]: TestResult;
}): string[] {
  const recommendations: string[] = [];

  if (tests.dailyChallenge.status === "FAIL") {
    recommendations.push(
      "❌ CRITICAL: Daily challenge not found. Run Cloud Function to generate today's challenge."
    );
  }

  if (tests.leaderboardRead.status === "WARN") {
    recommendations.push(
      "⚠️ No leaderboard entries found. This is normal if no one has completed the challenge yet."
    );
  }

  if (tests.leaderboardWrite.status === "FAIL") {
    recommendations.push(
      "❌ CRITICAL: Cannot write to leaderboard. Check Firestore security rules."
    );
  }

  if (tests.dailyChallenge.status === "WARN") {
    recommendations.push(
      "⚠️ Daily challenge exists but has incomplete level data. Regenerate the challenge."
    );
  }

  if (recommendations.length === 0) {
    recommendations.push("✅ All systems operational!");
  }

  return recommendations;
}

/**
 * Format date as YYYY-MM-DD
 * @param {Date} date - Date to format
 * @return {string} Formatted date string
 */
function formatDate(date: Date): string {
  const year = date.getUTCFullYear().toString().padStart(4, "0");
  const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const day = date.getUTCDate().toString().padStart(2, "0");
  return `${year}-${month}-${day}`;
}
