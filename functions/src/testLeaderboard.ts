import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Autonomous test endpoint for daily challenge leaderboard
 * GET /apiTestLeaderboard
 *
 * Tests the complete leaderboard flow server-side
 */
export const apiTestLeaderboard = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const logs: string[] = [];
  const log = (message: string) => {
    const timestamp = new Date().toISOString();
    logs.push(`[${timestamp}] ${message}`);
    console.log(message);
  };

  try {
    log("🏆 Starting leaderboard autonomous test");

    const db = admin.firestore();
    const today = new Date().toISOString().split("T")[0];

    log(`📅 Today's date: ${today}`);

    // Test 1: Check if challenge document exists
    log("📡 Test 1: Checking challenge document...");
    const challengeDoc = await db
      .collection("dailyChallenges")
      .doc(today)
      .get();

    if (!challengeDoc.exists) {
      log("❌ ISSUE: Challenge document doesn't exist");
      res.status(200).json({
        success: false,
        issue: "Challenge document not found",
        date: today,
        logs,
      });
      return;
    }

    log("✅ Challenge document exists");

    // Test 2: Check entries subcollection
    log("📡 Test 2: Checking entries subcollection...");
    const entriesSnapshot = await db
      .collection("dailyChallenges")
      .doc(today)
      .collection("entries")
      .get();

    log(`📊 Found ${entriesSnapshot.size} entry/entries`);

    if (entriesSnapshot.empty) {
      log("⚠️  No entries yet (expected if no one completed the challenge)");
      res.status(200).json({
        success: true,
        message: "No entries yet - this is normal if challenge not completed",
        entryCount: 0,
        logs,
      });
      return;
    }

    // Test 3: Validate entry structure
    log("📡 Test 3: Validating entry structure...");
    const firstEntry = entriesSnapshot.docs[0];
    const entryData = firstEntry.data();
    const entryFields = Object.keys(entryData);

    log(`🔍 Entry fields: ${entryFields.join(", ")}`);

    const requiredFields = [
      "userId",
      "username",
      "stars",
      "completionTime",
      "completedAt",
    ];
    const missingFields = requiredFields.filter(
      (field) => !(field in entryData)
    );

    if (missingFields.length > 0) {
      log(`❌ ISSUE: Missing required fields: ${missingFields.join(", ")}`);
      res.status(200).json({
        success: false,
        issue: "Entry missing required fields",
        missingFields,
        actualFields: entryFields,
        logs,
      });
      return;
    }

    log("✅ All required fields present");

    // Test 4: Check if entries can be queried with orderBy
    log("📡 Test 4: Testing query with orderBy...");
    try {
      const orderedSnapshot = await db
        .collection("dailyChallenges")
        .doc(today)
        .collection("entries")
        .orderBy("stars", "desc")
        .orderBy("completionTime", "asc")
        .get();

      log(`✅ Query succeeded, returned ${orderedSnapshot.size} entries`);

      // Test 5: Build sample leaderboard
      log("📡 Test 5: Building sample leaderboard...");
      const leaderboard = [];
      let rank = 1;

      for (const doc of orderedSnapshot.docs) {
        const data = doc.data();
        leaderboard.push({
          rank,
          username: data.username,
          stars: data.stars,
          completionTime: data.completionTime,
        });
        rank++;
      }

      log(`✅ Successfully built leaderboard with ${leaderboard.length} entries`);

      res.status(200).json({
        success: true,
        message: "Leaderboard test passed - all systems working",
        entryCount: leaderboard.length,
        leaderboard,
        logs,
      });
    } catch (queryError) {
      log(`❌ Query failed: ${queryError}`);
      res.status(200).json({
        success: false,
        issue: "Query with orderBy failed - may need index",
        error: String(queryError),
        logs,
      });
    }
  } catch (error) {
    log(`❌ EXCEPTION: ${error}`);
    res.status(200).json({
      success: false,
      issue: "Exception thrown",
      error: String(error),
      logs,
    });
  }
});
