/**
 * Type definitions for daily challenges and levels
 */

export interface DailyChallenge {
  id: string;
  createdAt: any; // Firestore Timestamp or string
  level: Level;
  completionCount: number;
  notificationSent: boolean;
}

export interface Level {
  id: string;
  size: number;
  cells: HexCell[];
  walls: HexEdge[];
  checkpointCount: number;
}

export interface HexCell {
  q: number;
  r: number;
  checkpoint?: number;
}

export interface HexEdge {
  q1: number;
  r1: number;
  q2: number;
  r2: number;
}

export interface HexCoordinate {
  q: number;
  r: number;
}

export interface LevelGenerationOptions {
  difficulty?: "easy" | "medium" | "hard";
  size?: number;
  wallDensity?: number;
}

export interface DailyChallengeCompletion {
  userId: string;
  dateId: string;
  stars: number;
  completionTime: number;
  completedAt: any; // Firestore Timestamp
  rank?: number;
}
