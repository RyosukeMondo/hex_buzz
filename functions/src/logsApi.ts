import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  sessionId: string;
  clientTime: string;
  data?: Record<string, unknown>;
}

/**
 * REST API endpoint to fetch recent diagnostic logs from Firestore.
 * GET /api/logs?limit=100&sessionId=xxx
 */
export const apiLogs = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const sessionId = req.query.sessionId as string | undefined;

    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection("diagnosticLogs")
      .orderBy("clientTime", "desc")
      .limit(limit);

    if (sessionId) {
      query = query.where("sessionId", "==", sessionId);
    }

    const snapshot = await query.get();
    const logs: LogEntry[] = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      logs.push({
        timestamp: data.timestamp?.toDate?.()?.toISOString() || data.clientTime,
        level: data.level || "INFO",
        message: data.message || "",
        sessionId: data.sessionId || "",
        clientTime: data.clientTime || "",
        data: data.data,
      });
    });

    res.status(200).json({
      success: true,
      count: logs.length,
      logs: logs,
    });
  } catch (error) {
    console.error("Error fetching logs:", error);
    res.status(500).json({
      success: false,
      error: String(error),
    });
  }
});
