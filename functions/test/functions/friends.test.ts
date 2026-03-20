/**
 * Tests for Friend Notification Cloud Functions
 * Tests onFriendRequestCreated and onFriendRequestAccepted handlers
 */

import "../setup";
import * as admin from "firebase-admin";
import {
  onFriendRequestCreatedHandler,
  onFriendRequestAcceptedHandler,
} from "../../src/functions/friends";
import { FriendRelation } from "../../src/types/social";

// Mock admin.firestore() and admin.messaging()
const mockGet = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet }));
const mockCollection = jest.fn(() => ({ doc: mockDoc }));
const mockSend = jest.fn();

jest.spyOn(admin, "firestore" as any).mockReturnValue({
  collection: mockCollection,
});

jest.spyOn(admin, "messaging" as any).mockReturnValue({
  send: mockSend,
});

describe("Friend Notification Functions", () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // Default mock: user exists with FCM token and social notifications enabled
    mockGet.mockResolvedValue({
      exists: true,
      data: () => ({
        username: "TestUser",
        fcmToken: "test-fcm-token-123",
        notificationPreferences: { social: true },
      }),
    });

    mockSend.mockResolvedValue("message-id-123");
  });

  describe("onFriendRequestCreatedHandler", () => {
    it("should send notification when a pending friend request is created", async () => {
      const snapData: FriendRelation = {
        friendId: "friend456",
        status: "pending",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const params = {
        userId: "recipient123",
        friendId: "friend456",
      };

      await onFriendRequestCreatedHandler(snapData, params);

      // Verify user lookup for initiator's name
      expect(mockCollection).toHaveBeenCalledWith("users");

      // Verify notification was sent
      expect(mockSend).toHaveBeenCalledTimes(1);
      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          token: "test-fcm-token-123",
          notification: expect.objectContaining({
            title: "New Friend Request",
            body: expect.stringContaining("friend request from TestUser"),
          }),
          data: expect.objectContaining({
            type: "friend_request",
            friendId: "initiator789",
            route: "/friends",
          }),
        })
      );
    });

    it("should not send notification for non-pending requests", async () => {
      const snapData: FriendRelation = {
        friendId: "friend456",
        status: "accepted",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const params = {
        userId: "recipient123",
        friendId: "friend456",
      };

      await onFriendRequestCreatedHandler(snapData, params);

      // No notification should be sent for already-accepted requests
      expect(mockSend).not.toHaveBeenCalled();
    });

    it("should handle missing recipient gracefully", async () => {
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ username: "Initiator" }),
      }).mockResolvedValueOnce({
        exists: false,
        data: () => undefined,
      });

      const snapData: FriendRelation = {
        friendId: "friend456",
        status: "pending",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const params = {
        userId: "nonexistent_user",
        friendId: "friend456",
      };

      // Should not throw
      await onFriendRequestCreatedHandler(snapData, params);

      // Notification send should not be called when user not found
      expect(mockSend).not.toHaveBeenCalled();
    });
  });

  describe("onFriendRequestAcceptedHandler", () => {
    it("should send notification when request status changes to accepted", async () => {
      const beforeData: FriendRelation = {
        friendId: "friend456",
        status: "pending",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const afterData: FriendRelation = {
        friendId: "friend456",
        status: "accepted",
        initiatedBy: "initiator789",
        createdAt: {},
        updatedAt: {},
      };

      const params = {
        userId: "accepter123",
        friendId: "friend456",
      };

      await onFriendRequestAcceptedHandler(beforeData, afterData, params);

      // Verify notification was sent to the initiator
      expect(mockSend).toHaveBeenCalledTimes(1);
      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          token: "test-fcm-token-123",
          notification: expect.objectContaining({
            title: "Friend Request Accepted",
            body: expect.stringContaining("accepted your friend request"),
          }),
          data: expect.objectContaining({
            type: "friend_accepted",
            friendId: "accepter123",
            route: "/friends",
          }),
        })
      );
    });

    it("should not send notification when status changes to rejected", async () => {
      const beforeData: FriendRelation = {
        friendId: "friend456",
        status: "pending",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const afterData: FriendRelation = {
        friendId: "friend456",
        status: "rejected",
        initiatedBy: "initiator789",
        createdAt: {},
        updatedAt: {},
      };

      const params = {
        userId: "user123",
        friendId: "friend456",
      };

      await onFriendRequestAcceptedHandler(beforeData, afterData, params);

      // No notification for rejection
      expect(mockSend).not.toHaveBeenCalled();
    });

    it("should not send notification when status has not changed", async () => {
      const beforeData: FriendRelation = {
        friendId: "friend456",
        status: "accepted",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const afterData: FriendRelation = {
        friendId: "friend456",
        status: "accepted",
        initiatedBy: "initiator789",
        createdAt: {},
        updatedAt: {},
      };

      const params = {
        userId: "user123",
        friendId: "friend456",
      };

      await onFriendRequestAcceptedHandler(beforeData, afterData, params);

      // No notification when status didn't change
      expect(mockSend).not.toHaveBeenCalled();
    });

    it("should include accepter username in the notification body", async () => {
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({
          username: "CoolPlayer42",
          fcmToken: "token-abc",
          notificationPreferences: {},
        }),
      });

      const beforeData: FriendRelation = {
        friendId: "friend456",
        status: "pending",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const afterData: FriendRelation = {
        friendId: "friend456",
        status: "accepted",
        initiatedBy: "initiator789",
        createdAt: {},
      };

      const params = {
        userId: "accepter123",
        friendId: "friend456",
      };

      await onFriendRequestAcceptedHandler(beforeData, afterData, params);

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            body: "CoolPlayer42 accepted your friend request!",
          }),
        })
      );
    });
  });
});
