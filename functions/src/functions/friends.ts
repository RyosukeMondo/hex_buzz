/**
 * Friend notification functions
 * Handles push notifications for friend requests and acceptances
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { FriendRelation } from "../types/social";
import { UserWithFCMToken } from "../types/notification";

/**
 * Sends a push notification to a single user by userId
 * Returns true if sent successfully, false otherwise
 */
async function sendNotificationToUser(
  recipientId: string,
  notificationType: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(recipientId).get();

  if (!userDoc.exists) {
    Logger.warn("notification_recipient_not_found", { recipientId });
    return false;
  }

  const userData = userDoc.data() as UserWithFCMToken;
  const preferences = userData.notificationPreferences || {};

  if (preferences.social === false) {
    Logger.info("notification_social_disabled", { recipientId });
    return false;
  }

  if (!userData.fcmToken) {
    Logger.warn("notification_no_fcm_token", { recipientId });
    return false;
  }

  try {
    await admin.messaging().send({
      token: userData.fcmToken,
      notification: { title, body },
      data: { type: notificationType, ...data },
    });

    Logger.info("notification_sent", { recipientId, type: notificationType });
    return true;
  } catch (error) {
    Logger.error("notification_send_failed", error as Error, {
      recipientId,
      type: notificationType,
    });
    return false;
  }
}

/**
 * Retrieves a user's display name by userId
 */
async function getUsername(userId: string): Promise<string> {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) {
    return "Someone";
  }

  const data = userDoc.data();
  return data?.username || data?.displayName || "Someone";
}

/**
 * Internal handler for friend request creation trigger
 * Exported for testing purposes
 */
export async function onFriendRequestCreatedHandler(
  snapData: FriendRelation,
  params: { userId: string; friendId: string }
): Promise<void> {
  return ErrorHandler.wrap(async () => {
    const { userId, friendId } = params;

    Logger.info("friend_request_created", {
      userId,
      friendId,
      status: snapData.status,
      initiatedBy: snapData.initiatedBy,
    });

    // Only send notification for pending requests
    if (snapData.status !== "pending") {
      return;
    }

    // The recipient of the notification is the document owner (userId),
    // since the initiator created a relation doc under the recipient's path
    const initiatorName = await getUsername(snapData.initiatedBy);

    await sendNotificationToUser(
      userId,
      "friend_request",
      "New Friend Request",
      `You have a new friend request from ${initiatorName}!`,
      {
        friendId: snapData.initiatedBy,
        route: "/friends",
      }
    );
  }, "onFriendRequestCreated");
}

/**
 * Internal handler for friend request acceptance trigger
 * Exported for testing purposes
 */
export async function onFriendRequestAcceptedHandler(
  beforeData: FriendRelation,
  afterData: FriendRelation,
  params: { userId: string; friendId: string }
): Promise<void> {
  return ErrorHandler.wrap(async () => {
    const { userId, friendId } = params;

    Logger.info("friend_relation_updated", {
      userId,
      friendId,
      oldStatus: beforeData.status,
      newStatus: afterData.status,
    });

    // Only send notification when status changes to 'accepted'
    if (beforeData.status === afterData.status || afterData.status !== "accepted") {
      return;
    }

    // Notify the original initiator that their request was accepted
    const accepterName = await getUsername(userId);

    await sendNotificationToUser(
      afterData.initiatedBy,
      "friend_accepted",
      "Friend Request Accepted",
      `${accepterName} accepted your friend request!`,
      {
        friendId: userId,
        route: "/friends",
      }
    );
  }, "onFriendRequestAccepted");
}

/**
 * Firestore trigger: sends notification when a friend request is created
 */
export const onFriendRequestCreated = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .firestore.document("friends/{userId}/relations/{friendId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() as FriendRelation;
    return onFriendRequestCreatedHandler(data, context.params as any);
  });

/**
 * Firestore trigger: sends notification when a friend request is accepted
 */
export const onFriendRequestAccepted = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .firestore.document("friends/{userId}/relations/{friendId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as FriendRelation;
    const after = change.after.data() as FriendRelation;
    return onFriendRequestAcceptedHandler(before, after, context.params as any);
  });
