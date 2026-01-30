/**
 * Daily Challenge functions
 * Handles challenge generation and retrieval
 */

import * as functions from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { LevelGeneratorService } from "../services/levelGenerator";
import { FirestoreService } from "../services/firestoreService";
import { NotificationService } from "../services/notificationService";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { Validator } from "../utils/validator";
import { DateUtils } from "../utils/dateUtils";
import { DailyChallenge, DailyChallengeCompletion } from "../types/challenge";
import { FieldValue } from "firebase-admin/firestore";

const levelGenerator = new LevelGeneratorService();
const firestore = new FirestoreService();
const notifications = new NotificationService();

/**
 * Generates a new daily challenge
 * Used by scheduled function and manual trigger
 */
export async function generateDailyChallenge(): Promise<void> {
  return ErrorHandler.wrap(async () => {
    const today = DateUtils.getToday();

    Logger.info("daily_challenge_generation_started", { date: today });

    // Check if challenge already exists
    const existing = await firestore.getDocument<DailyChallenge>("dailyChallenges", today);
    if (existing) {
      Logger.info("daily_challenge_already_exists", { date: today });
      return;
    }

    // Generate new challenge
    const level = await levelGenerator.generateChallenge({ difficulty: "medium" });

    // Save to Firestore
    await firestore.setDocument("dailyChallenges", today, {
      id: today,
      createdAt: FieldValue.serverTimestamp(),
      level,
      completionCount: 0,
      notificationSent: false,
    });

    Logger.info("daily_challenge_generated", { date: today, levelId: level.id });
  }, "generateDailyChallenge");
}

/**
 * Scheduled function to generate daily challenge at 11:00 UTC (8PM JST)
 */
export const scheduledDailyChallengeGenerator = functions
  .runWith({
    timeoutSeconds: 300,
    memory: "512MB",
  })
  .pubsub.schedule("0 11 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    return ErrorHandler.wrap(async () => {
      await generateDailyChallenge();
    }, "scheduledDailyChallengeGenerator");
  });

/**
 * HTTP function to manually trigger daily challenge generation
 */
export const manualGenerateChallenge = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    try {
      await generateDailyChallenge();
      res.status(200).json({
        success: true,
        message: "Daily challenge generated successfully",
      });
    } catch (error) {
      Logger.error("manual_challenge_generation_failed", error as Error);
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  });

/**
 * Callable function to get daily challenge
 */
export const getDailyChallenge = onCall(async (request) => {
  return ErrorHandler.wrap(async () => {
    const date = request.data?.date || DateUtils.getToday();

    Logger.info("daily_challenge_requested", {
      date,
      userId: request.auth?.uid,
    });

    const challenge = await firestore.getDocument<DailyChallenge>("dailyChallenges", date);

    if (!challenge) {
      throw new Error(`Challenge not found for date: ${date}`);
    }

    return challenge;
  }, "getDailyChallenge");
});

/**
 * Firestore trigger to send notifications when new daily challenge is created
 */
export const onDailyChallengeCreated = functions
  .runWith({
    timeoutSeconds: 300,
    memory: "512MB",
  })
  .firestore.document("dailyChallenges/{challengeId}")
  .onCreate(async (snap, context) => {
    return ErrorHandler.wrap(async () => {
      const challengeId = context.params.challengeId;
      const data = snap.data();

      Logger.info("daily_challenge_created", { challengeId });

      // Only send notification if not already sent
      if (data.notificationSent === false) {
        try {
          await notifications.sendDailyChallengeNotification(challengeId);
        } catch (error) {
          Logger.error("notification_send_failed", error as Error, { challengeId });
          // Don't throw - allow challenge creation to succeed even if notifications fail
        }
      }
    }, "onDailyChallengeCreated");
  });

/**
 * HTTP function to manually send push notifications
 */
export const manualSendNotification = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    try {
      const challengeId = req.body.challengeId || DateUtils.getToday();
      Logger.info("manual_notification_triggered", { challengeId });

      await notifications.sendDailyChallengeNotification(challengeId);

      res.status(200).json({
        success: true,
        message: `Notifications sent for challenge ${challengeId}`,
      });
    } catch (error) {
      Logger.error("manual_notification_failed", error as Error);
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  });

/**
 * Internal handler for daily challenge completion validation
 * Exported for testing purposes
 */
export async function validateDailyChallengeCompletionHandler(
  request: {
    auth?: { uid: string } | null;
    data: { dateId?: string; stars?: number; completionTimeMs?: number };
  },
  firestoreService: FirestoreService = firestore
) {
  return ErrorHandler.wrap(async () => {
    // 1. Verify user authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;
    const { dateId, stars, completionTimeMs } = request.data;

    Logger.info("daily_challenge_completion_validation_started", {
      userId,
      dateId,
      stars,
      completionTimeMs,
    });

    // 2. Validate input parameters
    Validator.required(dateId, "dateId");
    Validator.isString(dateId, "dateId");
    Validator.required(stars, "stars");
    Validator.isNumber(stars, "stars");
    Validator.required(completionTimeMs, "completionTimeMs");
    Validator.isNumber(completionTimeMs, "completionTimeMs");

    // After validation, we know these are defined
    const validatedDateId = dateId as string;
    const validatedStars = stars as number;
    const validatedCompletionTimeMs = completionTimeMs as number;

    // Additional range validations
    Validator.inRange(validatedStars, 0, 3, "stars");

    // Validate completion time is reasonable (> 1 second)
    if (validatedCompletionTimeMs < 1000) {
      throw new HttpsError(
        "invalid-argument",
        "completionTimeMs must be at least 1000ms"
      );
    }

    // 3. Check for existing completion
    const existingCompletion = await firestoreService.getDocument<DailyChallengeCompletion>(
      `dailyChallenges/${validatedDateId}/entries`,
      userId
    );

    if (existingCompletion) {
      throw new HttpsError(
        "already-exists",
        "User has already completed this daily challenge"
      );
    }

    // 4. Save completion to Firestore
    const completion: DailyChallengeCompletion = {
      userId,
      dateId: validatedDateId,
      stars: validatedStars,
      completionTimeMs: validatedCompletionTimeMs,
      completedAt: FieldValue.serverTimestamp(),
    };

    await firestoreService.setDocument(
      `dailyChallenges/${validatedDateId}/entries`,
      userId,
      completion
    );

    // 5. Calculate rank by querying leaderboard
    // Query entries ordered by stars DESC, completionTimeMs ASC
    const entries = await firestoreService.queryDocuments<DailyChallengeCompletion>(
      `dailyChallenges/${validatedDateId}/entries`,
      [
        { field: "stars", direction: "desc" },
        { field: "completionTimeMs", direction: "asc" },
      ]
    );

    // Find user's rank (1-indexed)
    const rank = entries.findIndex((entry) => entry.userId === userId) + 1;
    const totalPlayers = entries.length;

    Logger.info("daily_challenge_completion_validated", {
      userId,
      dateId: validatedDateId,
      stars: validatedStars,
      completionTimeMs: validatedCompletionTimeMs,
      rank,
      totalPlayers,
    });

    return {
      success: true,
      rank,
      totalPlayers,
    };
  }, "validateDailyChallengeCompletion");
}

/**
 * Callable function to validate and save daily challenge completion
 * Enforces one-attempt-per-day rule and calculates rank
 */
export const validateDailyChallengeCompletion = onCall(async (request) => {
  return validateDailyChallengeCompletionHandler(request);
});
