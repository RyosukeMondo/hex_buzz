/**
 * Timed Challenge functions
 * Handles score submission and leaderboard retrieval for timed challenges
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FirestoreService } from "../services/firestoreService";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { Validator } from "../utils/validator";
import {
  TimedChallengeScore,
  TimedChallengeLeaderboardEntry,
} from "../types/social";
import { FieldValue } from "firebase-admin/firestore";

const VALID_CONFIG_IDS = ["sprint", "marathon", "blitz"];
const LEADERBOARD_LIMIT = 100;

const firestore = new FirestoreService();

/**
 * Calculates a user's rank within a timed challenge leaderboard
 */
async function calculateRank(
  configId: string,
  userId: string,
  firestoreService: FirestoreService
): Promise<number> {
  const entries = await firestoreService.queryDocuments<TimedChallengeScore>(
    `timedChallengeScores/${configId}/entries`,
    [{ field: "score", direction: "desc" }]
  );

  const index = entries.findIndex((entry) => entry.userId === userId);
  return index >= 0 ? index + 1 : entries.length + 1;
}

/**
 * Internal handler for timed challenge score submission
 * Exported for testing purposes
 */
export async function submitTimedChallengeScoreHandler(
  request: {
    auth?: { uid: string } | null;
    data: {
      configId?: string;
      score?: number;
      puzzlesSolved?: number;
    };
  },
  firestoreService: FirestoreService = firestore
): Promise<{ success: true; rank: number }> {
  return ErrorHandler.wrap(async () => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;
    const { configId, score, puzzlesSolved } = request.data;

    Logger.info("timed_challenge_score_submission_started", {
      userId,
      configId,
      score,
      puzzlesSolved,
    });

    // Validate inputs
    Validator.required(configId, "configId");
    Validator.isString(configId, "configId");
    Validator.required(score, "score");
    Validator.isNumber(score, "score");
    Validator.required(puzzlesSolved, "puzzlesSolved");
    Validator.isNumber(puzzlesSolved, "puzzlesSolved");

    const validatedConfigId = configId as string;
    const validatedScore = score as number;
    const validatedPuzzlesSolved = puzzlesSolved as number;

    if (!VALID_CONFIG_IDS.includes(validatedConfigId)) {
      throw new HttpsError(
        "invalid-argument",
        `configId must be one of: ${VALID_CONFIG_IDS.join(", ")}`
      );
    }

    Validator.isPositive(validatedScore, "score");
    Validator.isPositive(validatedPuzzlesSolved, "puzzlesSolved");

    // Get username
    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(userId).get();
    const username = userDoc.exists
      ? userDoc.data()?.username || "Anonymous"
      : "Anonymous";

    // Check for existing score
    const collectionPath = `timedChallengeScores/${validatedConfigId}/entries`;
    const existing = await firestoreService.getDocument<TimedChallengeScore>(
      collectionPath,
      userId
    );

    // Only update if new score is higher
    if (existing && existing.score >= validatedScore) {
      Logger.info("timed_challenge_score_not_higher", {
        userId,
        configId: validatedConfigId,
        existingScore: existing.score,
        newScore: validatedScore,
      });

      const rank = await calculateRank(
        validatedConfigId,
        userId,
        firestoreService
      );
      return { success: true as const, rank };
    }

    // Save or update score
    const entry: TimedChallengeScore = {
      userId,
      username,
      configId: validatedConfigId,
      score: validatedScore,
      puzzlesSolved: validatedPuzzlesSolved,
      submittedAt: FieldValue.serverTimestamp(),
    };

    await firestoreService.setDocument(collectionPath, userId, entry);

    Logger.info("timed_challenge_score_submitted", {
      userId,
      configId: validatedConfigId,
      score: validatedScore,
      puzzlesSolved: validatedPuzzlesSolved,
    });

    const rank = await calculateRank(
      validatedConfigId,
      userId,
      firestoreService
    );

    return { success: true as const, rank };
  }, "submitTimedChallengeScore");
}

/**
 * Internal handler for timed challenge leaderboard retrieval
 * Exported for testing purposes
 */
export async function getTimedChallengeLeaderboardHandler(
  request: {
    auth?: { uid: string } | null;
    data: { configId?: string };
  },
  firestoreService: FirestoreService = firestore
): Promise<{ entries: TimedChallengeLeaderboardEntry[] }> {
  return ErrorHandler.wrap(async () => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { configId } = request.data;

    Validator.required(configId, "configId");
    Validator.isString(configId, "configId");

    const validatedConfigId = configId as string;

    if (!VALID_CONFIG_IDS.includes(validatedConfigId)) {
      throw new HttpsError(
        "invalid-argument",
        `configId must be one of: ${VALID_CONFIG_IDS.join(", ")}`
      );
    }

    Logger.info("timed_challenge_leaderboard_requested", {
      configId: validatedConfigId,
    });

    const scores = await firestoreService.queryDocuments<TimedChallengeScore>(
      `timedChallengeScores/${validatedConfigId}/entries`,
      [{ field: "score", direction: "desc" }],
      LEADERBOARD_LIMIT
    );

    const entries: TimedChallengeLeaderboardEntry[] = scores.map(
      (score, index) => ({
        rank: index + 1,
        userId: score.userId,
        username: score.username,
        score: score.score,
        puzzlesSolved: score.puzzlesSolved,
      })
    );

    Logger.info("timed_challenge_leaderboard_returned", {
      configId: validatedConfigId,
      entryCount: entries.length,
    });

    return { entries };
  }, "getTimedChallengeLeaderboard");
}

/**
 * Callable function: submit timed challenge score
 */
export const submitTimedChallengeScore = onCall(async (request) => {
  return submitTimedChallengeScoreHandler(request);
});

/**
 * Callable function: get timed challenge leaderboard
 */
export const getTimedChallengeLeaderboard = onCall(async (request) => {
  return getTimedChallengeLeaderboardHandler(request);
});
