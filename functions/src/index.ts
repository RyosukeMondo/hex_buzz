/**
 * Cloud Functions for HexBuzz
 * Entry point - exports all functions from modular structure
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export daily challenge functions
export {
  scheduledDailyChallengeGenerator,
  onDailyChallengeCreated,
  manualGenerateChallenge,
  manualSendNotification,
  getDailyChallenge,
  validateDailyChallengeCompletion,
} from "./functions/dailyChallenge";

// Export leaderboard functions
export {
  updateLeaderboardOnCompletion,
} from "./functions/leaderboard";

// Export diagnostic functions
export {
  apiDiagnostics,
} from "./functions/diagnostics";

// Export existing test functions (kept for backward compatibility)
export { apiLogs } from "./logsApi";
export { apiTestClientFlow } from "./testClientFlow";
export { apiTestLeaderboard } from "./testLeaderboard";
export { insertTestLeaderboardEntry } from "./insertTestLeaderboardEntry";
