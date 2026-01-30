/**
 * Type definitions for leaderboard entries
 */

export interface LeaderboardEntry {
  userId: string;
  username: string;
  avatarUrl?: string | null;
  totalStars: number;
  updatedAt: any; // Firestore Timestamp
  lastLevel?: string | null;
}

export interface DailyChallengeEntry {
  userId: string;
  username: string;
  stars: number;
  completionTime: number;
  totalStars: number;
  completedAt: any; // Firestore Timestamp
}

export interface ScoreSubmission {
  userId: string;
  levelId: string;
  totalStars: number;
  stars?: number;
  completionTime?: number;
}
