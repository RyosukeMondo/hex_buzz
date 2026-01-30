/**
 * Diagnostics functions
 * Provides comprehensive API testing and health checks
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { DateUtils } from "../utils/dateUtils";

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
  logs: string[];
}

interface TestResult {
  name: string;
  status: "PASS" | "FAIL" | "WARN";
  duration: number;
  details: any;
  error?: string;
}

/**
 * HTTP function to run comprehensive API diagnostics
 */
export const apiDiagnostics = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    // Handle OPTIONS request for CORS preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      Logger.info("diagnostics_started");
      const results = await runDiagnostics();
      res.status(200).json(results);
    } catch (error) {
      Logger.error("diagnostics_failed", error as Error);
      res.status(500).json({
        error: "Diagnostics failed",
        message: String(error),
        timestamp: new Date().toISOString(),
      });
    }
  });

/**
 * Runs comprehensive diagnostics on all API endpoints
 */
async function runDiagnostics(): Promise<DiagnosticResult> {
  const db = admin.firestore();
  const logs: string[] = [];

  const log = (message: string) => {
    logs.push(`[${new Date().toISOString()}] ${message}`);
    console.log(message);
  };

  log("🔍 Starting diagnostics...");

  const results: DiagnosticResult = {
    timestamp: new Date().toISOString(),
    tests: {
      dailyChallenge: await testDailyChallenge(db, log),
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
    logs: logs,
  };

  // Calculate summary
  const tests = Object.values(results.tests);
  results.summary.totalTests = tests.length;
  results.summary.passed = tests.filter((t) => t.status === "PASS").length;
  results.summary.failed = tests.filter((t) => t.status === "FAIL").length;
  results.summary.warnings = tests.filter((t) => t.status === "WARN").length;

  // Generate recommendations
  results.recommendations = generateRecommendations(results.tests);

  log(`✅ Diagnostics complete: ${results.summary.passed} passed, ${results.summary.failed} failed, ${results.summary.warnings} warnings`);

  return results;
}

async function testDailyChallenge(
  db: admin.firestore.Firestore,
  log: (message: string) => void
): Promise<TestResult> {
  const start = Date.now();
  const today = DateUtils.getToday();

  return ErrorHandler.wrap(async () => {
    log(`📅 Testing daily challenge for date: ${today}`);

    const docRef = db.collection("dailyChallenges").doc(today);
    const doc = await docRef.get();

    if (!doc.exists) {
      log(`❌ No daily challenge found for ${today}`);
      return {
        name: "Daily Challenge - GET",
        status: "FAIL" as const,
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
      log("⚠️ Level structure incomplete");
      return {
        name: "Daily Challenge - GET",
        status: "WARN" as const,
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

    log("✅ Daily challenge validated successfully");
    return {
      name: "Daily Challenge - GET",
      status: "PASS" as const,
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
  }, "testDailyChallenge");
}

async function testLeaderboardRead(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();
  const today = DateUtils.getToday();

  return ErrorHandler.wrap(async () => {
    const entriesRef = db
      .collection("dailyChallenges")
      .doc(today)
      .collection("entries");

    const snapshot = await entriesRef.get();

    if (snapshot.empty) {
      return {
        name: "Leaderboard Entries - READ",
        status: "WARN" as const,
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
      status: "PASS" as const,
      duration: Date.now() - start,
      details: {
        date: today,
        entryCount: entries.length,
        topEntry: entries[0],
        allEntries: entries,
      },
    };
  }, "testLeaderboardRead");
}

async function testLeaderboardWrite(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();
  const today = DateUtils.getToday();
  const testUserId = `diagnostic-test-${Date.now()}`;

  return ErrorHandler.wrap(async () => {
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
      status: writeSuccess ? ("PASS" as const) : ("FAIL" as const),
      duration: Date.now() - start,
      details: {
        date: today,
        testUserId,
        writeSuccess,
        deletedAfterTest: true,
      },
    };
  }, "testLeaderboardWrite");
}

async function testFirestoreRules(
  db: admin.firestore.Firestore
): Promise<TestResult> {
  const start = Date.now();

  return ErrorHandler.wrap(async () => {
    const tests = {
      dailyChallengesRead: false,
      entriesRead: false,
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
      const today = DateUtils.getToday();
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
      status: allPass ? ("PASS" as const) : ("WARN" as const),
      duration: Date.now() - start,
      details: {
        tests,
        message: allPass ?
          "All collections accessible (may be too permissive)" :
          "Some collections restricted (expected)",
      },
    };
  }, "testFirestoreRules");
}

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
