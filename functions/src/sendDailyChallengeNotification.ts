/**
 * Push Notification Sender
 * Sends FCM notifications to users when new daily challenge is available
 */

import * as admin from "firebase-admin";

/**
 * Sends push notifications to all users with FCM tokens
 * @param {string} challengeId ID of the new challenge
 * @return {Promise<void>} Promise that resolves when done
 */
export async function sendDailyChallengeNotification(
  challengeId: string
): Promise<void> {
  const db = admin.firestore();

  console.log(`Sending notifications for challenge ${challengeId}`);

  try {
    // Query users with FCM tokens
    const usersSnapshot = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .limit(500) // Process in batches
      .get();

    if (usersSnapshot.empty) {
      console.log("No users with FCM tokens found");
      return;
    }

    const tokens: string[] = [];
    const notificationPreferences: Record<string, boolean> = {};

    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      const token = data.fcmToken;
      const preferences = data.notificationPreferences || {};

      // Check if user has disabled daily challenge notifications
      if (preferences.dailyChallenges !== false) {
        tokens.push(token);
        notificationPreferences[token] = true;
      }
    });

    if (tokens.length === 0) {
      console.log("No users opted in for notifications");
      return;
    }

    // Prepare notification message
    const message = {
      notification: {
        title: "🐝 New Daily Challenge!",
        body: "A fresh puzzle awaits. Can you solve today's challenge?",
      },
      data: {
        type: "daily_challenge",
        challengeId: challengeId,
        route: "/daily-challenge",
      },
    };

    // Send batch notifications
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);

      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          ...message,
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        // Clean up invalid tokens
        response.responses.forEach((resp, idx) => {
          if (!resp.success &&
              (resp.error?.code === "messaging/invalid-registration-token" ||
               resp.error?.code === "messaging/registration-token-not-registered")) {
            console.log(`Removing invalid token: ${batch[idx]}`);
            // TODO: Remove token from user document
          }
        });
      } catch (error) {
        console.error(`Error sending batch: ${error}`);
        failureCount += batch.length;
      }
    }

    console.log(
      `✓ Notifications sent: ${successCount} success, ${failureCount} failed`
    );

    // Mark challenge as notification sent
    await db
      .collection("dailyChallenges")
      .doc(challengeId)
      .update({ notificationSent: true });
  } catch (error) {
    console.error(`Error sending notifications: ${error}`);
    throw error;
  }
}
