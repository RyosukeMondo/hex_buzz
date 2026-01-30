/**
 * Leaderboard functions
 * Handles leaderboard updates and queries
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { ScoreSubmission } from "../types/leaderboard";

/**
 * Firestore trigger to update leaderboard when user completes a level
 */
export const updateLeaderboardOnCompletion = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .firestore.document("scoreSubmissions/{submissionId}")
  .onCreate(async (snap) => {
    return ErrorHandler.wrap(async () => {
      const data = snap.data() as ScoreSubmission;
      const { userId, totalStars, levelId } = data;

      Logger.info("leaderboard_update_triggered", { userId, totalStars, levelId });

      const db = admin.firestore();

      // Get user info
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        Logger.error("leaderboard_update_failed", new Error("User not found"), { userId });
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
            lastLevel: levelId || null,
          });
          Logger.info("leaderboard_updated", { userId, oldStars: currentStars, newStars: totalStars });
        } else {
          Logger.info("leaderboard_not_updated", { userId, reason: "score_not_higher" });
        }
      } else {
        // Create new leaderboard entry
        await leaderboardRef.set({
          userId: userId,
          username: userData.username || "Anonymous",
          avatarUrl: userData.photoURL || null,
          totalStars: totalStars,
          updatedAt: FieldValue.serverTimestamp(),
          lastLevel: levelId || null,
        });
        Logger.info("leaderboard_entry_created", { userId, totalStars });
      }
    }, "updateLeaderboardOnCompletion");
  });
