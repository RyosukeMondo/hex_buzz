import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function triggered when a score submission is written to Firestore.
 * Updates user's total stars in users and leaderboard collections,
 * recomputes ranks, and sends notifications for significant rank changes.
 */
export const onScoreUpdate = functions.firestore
  .document("scoreSubmissions/{submissionId}")
  .onCreate(async (snap, context) => {
    const submission = snap.data();
    const userId = submission.userId;
    const levelId = submission.levelId;
    const stars = submission.stars;

    try {
      // Get user document
      const userRef = db.collection("users").doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        console.error(`User ${userId} not found`);
        return;
      }

      // Update user's level progress and total stars
      const levelProgressRef = userRef.collection("levelProgress").doc(levelId);
      const levelProgressDoc = await levelProgressRef.get();
      const currentStars = levelProgressDoc.exists ?
        levelProgressDoc.data()?.stars || 0 : 0;

      // Only update if new stars are higher
      if (stars > currentStars) {
        const starsDiff = stars - currentStars;

        // Update level progress
        await levelProgressRef.set({
          levelId,
          stars,
          completionTime: submission.time,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Update user's total stars
        await userRef.update({
          totalStars: admin.firestore.FieldValue.increment(starsDiff),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update leaderboard entry
        const leaderboardRef = db.collection("leaderboard").doc(userId);
        await leaderboardRef.set({
          userId,
          username: userDoc.data()?.displayName || "Anonymous",
          avatarUrl: userDoc.data()?.photoURL || null,
          totalStars: admin.firestore.FieldValue.increment(starsDiff),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Recompute ranks
        await recomputeRanks();

        // Check for rank change and send notification if significant
        const updatedLeaderboardDoc = await leaderboardRef.get();
        const newRank = updatedLeaderboardDoc.data()?.rank;
        const oldRank = userDoc.data()?.rank;

        if (oldRank && newRank && Math.abs(oldRank - newRank) >= 10) {
          const deviceToken = userDoc.data()?.deviceToken;
          if (deviceToken) {
            await sendRankChangeNotification(
              deviceToken,
              oldRank,
              newRank,
              updatedLeaderboardDoc.data()?.totalStars || 0
            );
          }
        }

        console.log(
          `Updated user ${userId} stars by ${starsDiff} (${currentStars} -> ${stars})`
        );
      } else {
        console.log(
          `Score ${stars} not better than current ${currentStars} for user ${userId}`
        );
      }
    } catch (error) {
      console.error("Error updating score:", error);
      throw error;
    }
  });

/**
 * Recomputes ranks for all users in the leaderboard based on totalStars.
 * Uses batched writes for efficiency.
 */
async function recomputeRanks(): Promise<void> {
  const leaderboardSnapshot = await db.collection("leaderboard")
    .orderBy("totalStars", "desc")
    .get();

  const batch = db.batch();
  let rank = 1;

  leaderboardSnapshot.forEach((doc) => {
    batch.update(doc.ref, { rank });
    rank++;
  });

  await batch.commit();
  console.log(`Recomputed ranks for ${leaderboardSnapshot.size} users`);
}

/**
 * Sends a push notification to a user about their rank change.
 */
async function sendRankChangeNotification(
  deviceToken: string,
  oldRank: number,
  newRank: number,
  totalStars: number
): Promise<void> {
  const rankChange = oldRank - newRank;
  const message: admin.messaging.Message = {
    token: deviceToken,
    notification: {
      title: rankChange > 0 ? "🎉 Rank Up!" : "Rank Changed",
      body: rankChange > 0 ?
        `You climbed ${rankChange} ranks! Now at #${newRank} with ${totalStars} stars!` :
        `Your rank changed to #${newRank}. Keep playing to climb higher!`,
    },
    data: {
      type: "rank_change",
      oldRank: oldRank.toString(),
      newRank: newRank.toString(),
      totalStars: totalStars.toString(),
    },
  };

  try {
    await messaging.send(message);
    console.log(`Sent rank change notification to user (${oldRank} -> ${newRank})`);
  } catch (error) {
    console.error("Error sending rank change notification:", error);
  }
}

/**
 * Scheduled function that runs daily at 00:00 UTC to generate a new daily challenge.
 * Generates or selects a level and stores it in the dailyChallenges collection.
 */
export const generateDailyChallenge = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const today = new Date();
      const dateString = today.toISOString().split("T")[0]; // YYYY-MM-DD

      // Check if challenge already exists (idempotency)
      const challengeRef = db.collection("dailyChallenges").doc(dateString);
      const existingChallenge = await challengeRef.get();

      if (existingChallenge.exists) {
        console.log(`Daily challenge for ${dateString} already exists`);
        return;
      }

      // Select a random level from a curated pool (levels 10-30 for moderate difficulty)
      // In production, this would use more sophisticated level selection logic
      const levelId = Math.floor(Math.random() * 21) + 10; // Random level between 10-30

      // Create daily challenge document
      await challengeRef.set({
        id: dateString,
        date: admin.firestore.Timestamp.fromDate(today),
        levelId,
        completionCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Generated daily challenge for ${dateString} with level ${levelId}`);

      // Trigger notification sending
      await sendDailyChallengeNotificationsInternal();
    } catch (error) {
      console.error("Error generating daily challenge:", error);
      throw error;
    }
  });

/**
 * Sends push notifications to all users subscribed to the daily_challenge topic
 * about the new daily challenge.
 */
async function sendDailyChallengeNotificationsInternal(): Promise<void> {
  const message: admin.messaging.Message = {
    topic: "daily_challenge",
    notification: {
      title: "🌟 New Daily Challenge!",
      body: "A fresh challenge awaits! Play now to climb the daily leaderboard.",
    },
    data: {
      type: "daily_challenge",
      screen: "daily_challenge",
    },
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log("Sent daily challenge notification:", response);
  } catch (error) {
    console.error("Error sending daily challenge notification:", error);
  }
}

/**
 * HTTP callable function to manually trigger daily challenge notifications.
 * Useful for testing or manual triggers.
 */
export const sendDailyChallengeNotifications = functions.https
  .onCall(async (data, context) => {
    // Verify that the request is from an authenticated user (optional: add admin check)
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to trigger notifications"
      );
    }

    await sendDailyChallengeNotificationsInternal();
    return { success: true, message: "Notifications sent" };
  });

/**
 * Cloud Function triggered when a new user document is created.
 * Initializes the user's leaderboard entry and subscribes them to notifications.
 */
export const onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();

    try {
      // Initialize leaderboard entry with 0 stars
      const leaderboardRef = db.collection("leaderboard").doc(userId);
      await leaderboardRef.set({
        userId,
        username: userData.displayName || "Anonymous",
        avatarUrl: userData.photoURL || null,
        totalStars: 0,
        rank: 999999, // Will be updated when scores are submitted
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Initialized leaderboard entry for user ${userId}`);

      // Subscribe to daily challenge topic if device token exists
      const deviceToken = userData.deviceToken;
      if (deviceToken) {
        try {
          await messaging.subscribeToTopic([deviceToken], "daily_challenge");
          console.log(`Subscribed user ${userId} to daily_challenge topic`);
        } catch (error) {
          console.error(`Error subscribing user ${userId} to topic:`, error);
        }
      }
    } catch (error) {
      console.error("Error in onUserCreated:", error);
      throw error;
    }
  });

/**
 * HTTP callable function for admin operations (testing/manual triggers).
 * Example: Manually recompute all ranks.
 */
export const recomputeAllRanks = functions.https
  .onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    await recomputeRanks();
    return { success: true, message: "Ranks recomputed successfully" };
  });
