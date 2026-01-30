/**
 * Notification service
 * Handles FCM push notifications to users
 */

import * as admin from "firebase-admin";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { FirestoreService } from "./firestoreService";
import { UserWithFCMToken } from "../types/notification";

export class NotificationService {
  private firestore = new FirestoreService();

  /**
   * Sends daily challenge notification to all opted-in users
   */
  async sendDailyChallengeNotification(challengeId: string): Promise<void> {
    return ErrorHandler.wrap(async () => {
      Logger.info("sending_notifications", { challengeId });

      // Query users with FCM tokens
      const usersSnapshot = await this.firestore
        .getCollectionReference("users")
        .where("fcmToken", "!=", null)
        .limit(500)
        .get();

      if (usersSnapshot.empty) {
        Logger.warn("no_fcm_tokens_found");
        return;
      }

      const tokens: string[] = [];

      usersSnapshot.forEach((doc) => {
        const data = doc.data() as UserWithFCMToken;
        const preferences = data.notificationPreferences || {};

        // Check if user has disabled daily challenge notifications
        if (preferences.dailyChallenges !== false) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        Logger.warn("no_users_opted_in");
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
      const result = await this.sendBatchNotifications(tokens, message);

      Logger.info("notifications_sent", {
        successCount: result.successCount,
        failureCount: result.failureCount,
      });

      // Mark challenge as notification sent
      await this.firestore.updateDocument("dailyChallenges", challengeId, {
        notificationSent: true,
      });
    }, "sendDailyChallengeNotification");
  }

  /**
   * Sends batch notifications to multiple tokens
   */
  private async sendBatchNotifications(
    tokens: string[],
    message: {
      notification: { title: string; body: string };
      data: { [key: string]: string };
    }
  ): Promise<{ successCount: number; failureCount: number }> {
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

        // Log invalid tokens
        response.responses.forEach((resp, idx) => {
          if (!resp.success &&
              (resp.error?.code === "messaging/invalid-registration-token" ||
               resp.error?.code === "messaging/registration-token-not-registered")) {
            Logger.warn("invalid_fcm_token", { token: batch[idx] });
          }
        });
      } catch (error) {
        Logger.error("batch_notification_failed", error as Error, { batchSize: batch.length });
        failureCount += batch.length;
      }
    }

    return { successCount, failureCount };
  }
}
