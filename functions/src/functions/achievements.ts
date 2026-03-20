/**
 * Achievement functions
 * Handles achievement unlocking, storage, and friend notifications
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FirestoreService } from "../services/firestoreService";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { Validator } from "../utils/validator";
import { Achievement, FriendRelation } from "../types/social";
import { UserWithFCMToken } from "../types/notification";
import { FieldValue } from "firebase-admin/firestore";

const firestore = new FirestoreService();

/**
 * Retrieves the list of accepted friend user IDs for a given user
 */
async function getAcceptedFriendIds(userId: string): Promise<string[]> {
  const relations = await firestore.queryCollection<FriendRelation>(
    `friends/${userId}/relations`,
    [{ field: "status", op: "==", value: "accepted" }]
  );

  return relations.map((r) => r.friendId);
}

/**
 * Sends achievement notifications to a list of friend user IDs
 */
async function notifyFriendsOfAchievement(
  friendIds: string[],
  username: string,
  achievementName: string
): Promise<void> {
  const db = admin.firestore();
  const tokens: string[] = [];

  for (const friendId of friendIds) {
    const friendDoc = await db.collection("users").doc(friendId).get();
    if (!friendDoc.exists) continue;

    const friendData = friendDoc.data() as UserWithFCMToken;
    const preferences = friendData.notificationPreferences || {};

    if (preferences.social !== false && friendData.fcmToken) {
      tokens.push(friendData.fcmToken);
    }
  }

  if (tokens.length === 0) {
    Logger.info("achievement_no_friends_to_notify");
    return;
  }

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Achievement Unlocked!",
        body: `${username} unlocked "${achievementName}"!`,
      },
      data: {
        type: "friend_achievement",
        route: "/achievements",
      },
    });

    Logger.info("achievement_notifications_sent", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error) {
    Logger.error("achievement_notification_failed", error as Error);
  }
}

/**
 * Internal handler for achievement unlocking
 * Exported for testing purposes
 */
export async function onAchievementUnlockedHandler(
  request: {
    auth?: { uid: string } | null;
    data: {
      achievementId?: string;
      name?: string;
      description?: string;
      notifyFriends?: boolean;
    };
  },
  firestoreService: FirestoreService = firestore
): Promise<{ success: true }> {
  return ErrorHandler.wrap(async () => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;
    const { achievementId, name, description, notifyFriends } = request.data;

    Logger.info("achievement_unlock_started", { userId, achievementId });

    Validator.required(achievementId, "achievementId");
    Validator.isString(achievementId, "achievementId");
    Validator.required(name, "name");
    Validator.isString(name, "name");

    const validatedId = achievementId as string;
    const validatedName = name as string;
    const validatedDescription = description || "";
    const shouldNotifyFriends = notifyFriends !== false;

    // Check if achievement already unlocked
    const existing = await firestoreService.getDocument<Achievement>(
      `achievements/${userId}`,
      validatedId
    );

    if (existing) {
      Logger.info("achievement_already_unlocked", {
        userId,
        achievementId: validatedId,
      });
      return { success: true as const };
    }

    // Store achievement
    const achievement: Achievement = {
      achievementId: validatedId,
      userId,
      name: validatedName,
      description: validatedDescription,
      unlockedAt: FieldValue.serverTimestamp(),
      notifyFriends: shouldNotifyFriends,
    };

    await firestoreService.setDocument(
      `achievements/${userId}`,
      validatedId,
      achievement
    );

    Logger.info("achievement_unlocked", {
      userId,
      achievementId: validatedId,
      name: validatedName,
    });

    // Notify friends if requested
    if (shouldNotifyFriends) {
      try {
        const db = admin.firestore();
        const userDoc = await db.collection("users").doc(userId).get();
        const username = userDoc.exists
          ? userDoc.data()?.username || "A friend"
          : "A friend";

        const friendIds = await getAcceptedFriendIds(userId);

        if (friendIds.length > 0) {
          await notifyFriendsOfAchievement(friendIds, username, validatedName);
        }
      } catch (error) {
        Logger.error("achievement_friend_notify_failed", error as Error, {
          userId,
          achievementId: validatedId,
        });
        // Don't throw - achievement was saved successfully
      }
    }

    return { success: true as const };
  }, "onAchievementUnlocked");
}

/**
 * Callable function: record achievement unlock and notify friends
 */
export const onAchievementUnlocked = onCall(async (request) => {
  return onAchievementUnlockedHandler(request);
});
