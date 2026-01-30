/**
 * Centralized error handler for Cloud Functions
 * Converts errors to appropriate HttpsError types for consistent client handling
 */

import { Logger } from "./logger";
import { HttpsError } from "firebase-functions/v2/https";

export class ErrorHandler {
  static handle(error: Error, context: string): never {
    Logger.error("function_error", error, { context });

    if (error instanceof HttpsError) {
      throw error;
    }

    // Convert to HttpsError for consistent client handling
    if (error.message.includes("not found")) {
      throw new HttpsError("not-found", error.message);
    }

    if (error.message.includes("unauthorized")) {
      throw new HttpsError("unauthenticated", error.message);
    }

    if (error.message.includes("permission")) {
      throw new HttpsError("permission-denied", error.message);
    }

    // Default to internal error
    throw new HttpsError("internal", "An unexpected error occurred", {
      original: error.message,
    });
  }

  static async wrap<T>(
    fn: () => Promise<T>,
    context: string
  ): Promise<T> {
    try {
      return await fn();
    } catch (error) {
      this.handle(error as Error, context);
    }
  }
}
