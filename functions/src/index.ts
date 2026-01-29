/**
 * Cloud Functions for HexBuzz
 * Handles automated daily challenges, notifications, and leaderboard updates
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { generateDailyChallenge } from "./dailyChallengeGenerator";
import { sendDailyChallengeNotification } from "./sendDailyChallengeNotification";
import { runDiagnostics } from "./diagnostics";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Scheduled function to generate daily challenge at 8PM JST
 * Runs every day at 11:00 UTC (8PM JST = UTC+9)
 */
export const scheduledDailyChallengeGenerator = functions
  .runWith({
    timeoutSeconds: 300,
    memory: "512MB",
  })
  .pubsub.schedule("0 11 * * *")
  .timeZone("UTC")
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  .onRun(async (_context) => {
    console.log("Scheduled daily challenge generation triggered");
    try {
      await generateDailyChallenge();
      console.log("Daily challenge generated successfully");
    } catch (error) {
      console.error("Error in scheduled challenge generation:", error);
      throw error;
    }
  });

/**
 * Firestore trigger to send notifications when new daily challenge is created
 */
export const onDailyChallengeCreated = functions
  .runWith({
    timeoutSeconds: 300,
    memory: "512MB",
  })
  .firestore.document("dailyChallenges/{challengeId}")
  .onCreate(async (snap, context) => {
    const challengeId = context.params.challengeId;
    const data = snap.data();

    console.log(`New daily challenge created: ${challengeId}`);

    // Only send notification if not already sent
    if (data.notificationSent === false) {
      try {
        await sendDailyChallengeNotification(challengeId);
        console.log("Notifications sent successfully");
      } catch (error) {
        console.error("Error sending notifications:", error);
        // Don't throw - allow challenge creation to succeed even if notifications fail
      }
    }
  });

/**
 * HTTP function to manually trigger daily challenge generation (for testing)
 */
export const manualGenerateChallenge = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    // Only allow POST requests
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    try {
      console.log("Manual challenge generation triggered");
      await generateDailyChallenge();
      res.status(200).json({
        success: true,
        message: "Daily challenge generated successfully",
      });
    } catch (error) {
      console.error("Error in manual challenge generation:", error);
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  });

/**
 * HTTP function to manually send push notifications (for testing)
 */
export const manualSendNotification = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    try {
      const challengeId = req.body.challengeId || new Date().toISOString().split("T")[0];
      console.log(`Manual notification trigger for challenge: ${challengeId}`);
      await sendDailyChallengeNotification(challengeId);
      res.status(200).json({
        success: true,
        message: `Notifications sent for challenge ${challengeId}`,
      });
    } catch (error) {
      console.error("Error sending manual notification:", error);
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  });

/**
 * Firestore trigger to update leaderboard when user completes a level
 */
export const updateLeaderboardOnCompletion = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .firestore.document("scoreSubmissions/{submissionId}")
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  .onCreate(async (snap, _context) => {
    const data = snap.data();
    const userId = data.userId;
    const totalStars = data.totalStars;

    console.log(`Updating leaderboard for user ${userId}, stars: ${totalStars}`);

    try {
      const db = admin.firestore();

      // Get user info
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.error(`User ${userId} not found`);
        return;
      }

      const userData = userDoc.data()!;

      // Update or create leaderboard entry
      const leaderboardRef = db.collection("leaderboard").doc(userId);
      const leaderboardDoc = await leaderboardRef.get();

      if (leaderboardDoc.exists) {
        // Update if new score is higher
        const currentStars = leaderboardDoc.data()!.totalStars || 0;
        if (totalStars > currentStars) {
          await leaderboardRef.update({
            totalStars: totalStars,
            updatedAt: FieldValue.serverTimestamp(),
            lastLevel: data.levelId || null,
          });
          console.log(`✓ Leaderboard updated for ${userId}`);
        }
      } else {
        // Create new leaderboard entry
        await leaderboardRef.set({
          userId: userId,
          username: userData.username || "Anonymous",
          avatarUrl: userData.photoURL || null,
          totalStars: totalStars,
          updatedAt: FieldValue.serverTimestamp(),
          lastLevel: data.levelId || null,
        });
        console.log(`✓ Leaderboard entry created for ${userId}`);
      }
    } catch (error) {
      console.error("Error updating leaderboard:", error);
      throw error;
    }
  });

/**
 * HTTP function to run comprehensive API diagnostics
 * Returns JSON with all test results - zero UAT required
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
      console.log("Running API diagnostics...");
      const results = await runDiagnostics();

      res.status(200).json(results);
    } catch (error) {
      console.error("Error running diagnostics:", error);
      res.status(500).json({
        error: "Diagnostics failed",
        message: String(error),
        timestamp: new Date().toISOString(),
      });
    }
  });
