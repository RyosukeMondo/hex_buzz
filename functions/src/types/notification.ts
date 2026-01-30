/**
 * Type definitions for notifications
 */

export interface NotificationMessage {
  notification: {
    title: string;
    body: string;
  };
  data: {
    type: string;
    challengeId?: string;
    route?: string;
    [key: string]: string | undefined;
  };
}

export interface NotificationPreferences {
  dailyChallenges?: boolean;
  achievements?: boolean;
  social?: boolean;
}

export interface UserWithFCMToken {
  fcmToken: string;
  notificationPreferences?: NotificationPreferences;
}
