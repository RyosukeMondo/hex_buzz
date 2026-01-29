import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Autonomous test that simulates client-side daily challenge loading
 * GET /api/testClientFlow
 *
 * This mimics exactly what the Flutter app does, so we can diagnose issues
 * without requiring a real client visit.
 */
export const apiTestClientFlow = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const logs: string[] = [];
  const log = (message: string) => {
    const timestamp = new Date().toISOString();
    logs.push(`[${timestamp}] ${message}`);
    console.log(message);
  };

  try {
    log("🚀 Starting autonomous client flow test");

    const db = admin.firestore();
    const today = new Date().toISOString().split("T")[0];

    log(`📅 Today's date: ${today}`);
    log(`📡 Querying: dailyChallenges/${today}`);

    // Step 1: Query Firestore (same as Flutter app)
    const docRef = db.collection("dailyChallenges").doc(today);
    const doc = await docRef.get();

    log(`📄 Document exists: ${doc.exists}`);

    if (!doc.exists) {
      log("❌ ISSUE FOUND: Document does not exist");
      res.status(200).json({
        success: false,
        issue: "Daily challenge document not found",
        date: today,
        logs,
      });
      return;
    }

    const data = doc.data();
    if (!data) {
      log("❌ ISSUE FOUND: Document data is null");
      res.status(200).json({
        success: false,
        issue: "Document data is null",
        logs,
      });
      return;
    }

    log("✅ Document data retrieved");
    log(`📊 Top-level keys: ${Object.keys(data).join(", ")}`);

    // Step 2: Extract level data (same as Flutter app)
    const levelData = data.level;

    if (!levelData) {
      log("❌ ISSUE FOUND: Level data is missing");
      res.status(200).json({
        success: false,
        issue: "Level data is null or undefined",
        documentKeys: Object.keys(data),
        logs,
      });
      return;
    }

    log("✅ Level data present");
    log(`🎮 Level data type: ${typeof levelData}`);
    log(`🎮 Level keys: ${Object.keys(levelData as object).join(", ")}`);

    // Step 3: Validate level structure (same as Level.fromJson())
    const requiredFields = ["id", "size", "cells", "walls", "checkpointCount"];
    const missingFields = requiredFields.filter((field) => !(field in (levelData as object)));

    if (missingFields.length > 0) {
      log(`❌ ISSUE FOUND: Missing required fields: ${missingFields.join(", ")}`);
      res.status(200).json({
        success: false,
        issue: "Level data missing required fields",
        missingFields,
        actualFields: Object.keys(levelData as object),
        logs,
      });
      return;
    }

    log("✅ All required level fields present");

    // Step 4: Validate cells array
    const level = levelData as { cells?: unknown[]; walls?: unknown[] };
    if (!Array.isArray(level.cells)) {
      log("❌ ISSUE FOUND: Cells is not an array");
      res.status(200).json({
        success: false,
        issue: "Cells field is not an array",
        cellsType: typeof level.cells,
        logs,
      });
      return;
    }

    log(`✅ Cells is array with ${level.cells.length} items`);
    if (level.cells.length > 0) {
      log(`📦 First cell: ${JSON.stringify(level.cells[0])}`);
    }

    // Step 5: Validate walls array
    if (!Array.isArray(level.walls)) {
      log("❌ ISSUE FOUND: Walls is not an array");
      res.status(200).json({
        success: false,
        issue: "Walls field is not an array",
        wallsType: typeof level.walls,
        logs,
      });
      return;
    }

    log(`✅ Walls is array with ${level.walls.length} items`);

    // Success!
    log("🎉 SUCCESS: All validation passed!");
    log("✅ Daily challenge would load correctly in Flutter app");

    res.status(200).json({
      success: true,
      message: "Client flow test passed - challenge should load in app",
      date: today,
      levelSummary: {
        size: (levelData as { size: number }).size,
        cellCount: level.cells.length,
        wallCount: level.walls.length,
        checkpointCount: (levelData as { checkpointCount: number }).checkpointCount,
      },
      logs,
    });
  } catch (error) {
    log(`❌ EXCEPTION: ${error}`);
    res.status(200).json({
      success: false,
      issue: "Exception thrown",
      error: String(error),
      logs,
    });
  }
});
