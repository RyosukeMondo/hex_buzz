/**
 * Type definitions for social features (friends, achievements, sharing)
 */

export type FriendRelationStatus = "pending" | "accepted" | "rejected";

export interface FriendRelation {
  friendId: string;
  status: FriendRelationStatus;
  initiatedBy: string;
  createdAt: any; // Firestore Timestamp
  updatedAt?: any; // Firestore Timestamp
}

export interface Achievement {
  achievementId: string;
  userId: string;
  name: string;
  description: string;
  unlockedAt: any; // Firestore Timestamp
  notifyFriends: boolean;
}

export interface TimedChallengeScore {
  userId: string;
  username: string;
  configId: string;
  score: number;
  puzzlesSolved: number;
  submittedAt: any; // Firestore Timestamp
}

export interface TimedChallengeLeaderboardEntry {
  rank: number;
  userId: string;
  username: string;
  score: number;
  puzzlesSolved: number;
}

export interface SharedLevel {
  levelId: string;
  shareCode: string;
  creatorId: string;
  creatorName: string;
  title: string;
  description: string;
  levelData: Record<string, any>;
  createdAt: any; // Firestore Timestamp
  playCount: number;
}
