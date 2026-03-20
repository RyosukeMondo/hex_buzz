/**
 * Level Sharing functions
 * Handles publishing and retrieving user-created levels
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FirestoreService } from "../services/firestoreService";
import { Logger } from "../utils/logger";
import { ErrorHandler } from "../utils/errorHandler";
import { Validator } from "../utils/validator";
import { SharedLevel } from "../types/social";
import { FieldValue } from "firebase-admin/firestore";

const SHARE_CODE_LENGTH = 8;
const SHARE_CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

const firestore = new FirestoreService();

/**
 * Generates a short alphanumeric share code
 * Uses characters that avoid ambiguity (no 0/O, 1/I/l)
 */
function generateShareCode(): string {
  let code = "";
  for (let i = 0; i < SHARE_CODE_LENGTH; i++) {
    const index = Math.floor(Math.random() * SHARE_CODE_CHARS.length);
    code += SHARE_CODE_CHARS[index];
  }
  return code;
}

/**
 * Generates a unique share code that does not collide with existing codes
 */
async function generateUniqueShareCode(
  firestoreService: FirestoreService
): Promise<string> {
  const maxAttempts = 10;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const code = generateShareCode();

    const existing = await firestoreService.queryCollection<SharedLevel>(
      "sharedLevels",
      [{ field: "shareCode", op: "==", value: code }]
    );

    if (existing.length === 0) {
      return code;
    }

    Logger.warn("share_code_collision", { code, attempt });
  }

  throw new HttpsError(
    "internal",
    "Failed to generate unique share code after multiple attempts"
  );
}

/**
 * Internal handler for publishing a shared level
 * Exported for testing purposes
 */
export async function publishLevelHandler(
  request: {
    auth?: { uid: string } | null;
    data: {
      title?: string;
      description?: string;
      levelData?: Record<string, any>;
    };
  },
  firestoreService: FirestoreService = firestore
): Promise<{ success: true; shareCode: string }> {
  return ErrorHandler.wrap(async () => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;
    const { title, description, levelData } = request.data;

    Logger.info("level_publish_started", { userId, title });

    Validator.required(title, "title");
    Validator.isString(title, "title");
    Validator.required(levelData, "levelData");

    const validatedTitle = title as string;
    const validatedDescription = description || "";

    if (typeof levelData !== "object" || Array.isArray(levelData)) {
      throw new HttpsError("invalid-argument", "levelData must be an object");
    }

    // Get creator name
    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(userId).get();
    const creatorName = userDoc.exists
      ? userDoc.data()?.username || "Anonymous"
      : "Anonymous";

    // Generate unique share code
    const shareCode = await generateUniqueShareCode(firestoreService);

    // Generate level ID
    const levelRef = db.collection("sharedLevels").doc();
    const levelId = levelRef.id;

    const sharedLevel: SharedLevel = {
      levelId,
      shareCode,
      creatorId: userId,
      creatorName,
      title: validatedTitle,
      description: validatedDescription,
      levelData: levelData as Record<string, any>,
      createdAt: FieldValue.serverTimestamp(),
      playCount: 0,
    };

    await firestoreService.setDocument("sharedLevels", levelId, sharedLevel);

    Logger.info("level_published", { userId, levelId, shareCode });

    return { success: true as const, shareCode };
  }, "publishLevel");
}

/**
 * Internal handler for retrieving a shared level by code
 * Exported for testing purposes
 */
export async function getSharedLevelHandler(
  request: {
    auth?: { uid: string } | null;
    data: { shareCode?: string };
  },
  firestoreService: FirestoreService = firestore
): Promise<{ level: SharedLevel }> {
  return ErrorHandler.wrap(async () => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { shareCode } = request.data;

    Validator.required(shareCode, "shareCode");
    Validator.isString(shareCode, "shareCode");

    const validatedCode = (shareCode as string).toUpperCase();

    Logger.info("shared_level_requested", { shareCode: validatedCode });

    const results = await firestoreService.queryCollection<SharedLevel>(
      "sharedLevels",
      [{ field: "shareCode", op: "==", value: validatedCode }]
    );

    if (results.length === 0) {
      throw new HttpsError(
        "not-found",
        `No shared level found with code: ${validatedCode}`
      );
    }

    const level = results[0];

    Logger.info("shared_level_found", {
      levelId: level.levelId,
      shareCode: validatedCode,
    });

    return { level };
  }, "getSharedLevel");
}

/**
 * Callable function: publish a user-created level
 */
export const publishLevel = onCall(async (request) => {
  return publishLevelHandler(request);
});

/**
 * Callable function: get a shared level by code
 */
export const getSharedLevel = onCall(async (request) => {
  return getSharedLevelHandler(request);
});
