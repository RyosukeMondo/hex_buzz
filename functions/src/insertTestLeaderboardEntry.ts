import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Simple HTTP function to insert a test leaderboard entry
 * Call with: curl -X POST https://REGION-PROJECT.cloudfunctions.net/insertTestLeaderboardEntry
 */
export const insertTestLeaderboardEntry = functions
  .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const db = admin.firestore();
      const today = new Date();
      const dateId = today.toISOString().split("T")[0]; // YYYY-MM-DD

      const testUserId = `test-user-${Date.now()}`;
      const testData = {
        userId: testUserId,
        username: "Test Player",
        stars: 3,
        completionTimeMs: 45000,
        completedAt: today.toISOString(),
      };

      console.log(`📝 Inserting test entry for ${dateId}:`, testData);

      // Insert the test entry
      await db
        .collection("dailyChallenges")
        .doc(dateId)
        .collection("entries")
        .doc(testUserId)
        .set(testData);

      console.log("✅ Test entry inserted successfully");

      // Verify it was inserted
      const verifyDoc = await db
        .collection("dailyChallenges")
        .doc(dateId)
        .collection("entries")
        .doc(testUserId)
        .get();

      res.status(200).json({
        success: true,
        message: "Test entry inserted successfully",
        data: {
          dateId,
          userId: testUserId,
          verified: verifyDoc.exists,
        },
      });
    } catch (error) {
      console.error("❌ Error inserting test entry:", error);
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  });
