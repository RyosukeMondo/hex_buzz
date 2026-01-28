/**
 * Daily Challenge Generator
 * Scheduled function to create a new daily challenge at midnight UTC
 */

import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { generateLevel } from "./levelGenerator";

/**
 * Generates today's daily challenge and stores in Firestore
 */
export async function generateDailyChallenge(): Promise<void> {
  const db = admin.firestore();
  const today = new Date();
  const dateStr = formatDate(today);

  console.log(`Generating daily challenge for ${dateStr}`);

  try {
    // Check if challenge already exists
    const challengeRef = db.collection("dailyChallenges").doc(dateStr);
    const existingDoc = await challengeRef.get();

    if (existingDoc.exists) {
      console.log(`Challenge for ${dateStr} already exists, skipping`);
      return;
    }

    // Generate level
    const level = generateLevel(dateStr, 8);

    // Store in Firestore
    await challengeRef.set({
      id: dateStr,
      createdAt: FieldValue.serverTimestamp(),
      level: level,
      completionCount: 0,
      notificationSent: false,
    });

    console.log(`✓ Daily challenge created for ${dateStr}`);
  } catch (error) {
    console.error(`Error generating daily challenge: ${error}`);
    throw error;
  }
}

/**
 * Formats a Date as YYYY-MM-DD
 * @param {Date} date Date to format
 * @return {string} Formatted date string
 */
function formatDate(date: Date): string {
  const year = date.getUTCFullYear().toString().padStart(4, "0");
  const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const day = date.getUTCDate().toString().padStart(2, "0");
  return `${year}-${month}-${day}`;
}
