/**
 * Tests for Daily Challenge Cloud Functions
 * Tests validateDailyChallengeCompletion function
 */

import "../setup";
import { validateDailyChallengeCompletionHandler } from "../../src/functions/dailyChallenge";
import { FirestoreService } from "../../src/services/firestoreService";
import { DailyChallengeCompletion } from "../../src/types/challenge";

// Mock FirestoreService
jest.mock("../../src/services/firestoreService", () => {
  return {
    FirestoreService: jest.fn().mockImplementation(() => {
      return {
        getDocument: jest.fn(),
        setDocument: jest.fn(),
        queryDocuments: jest.fn(),
      };
    }),
  };
});

describe("validateDailyChallengeCompletion", () => {
  let mockFirestoreService: jest.Mocked<FirestoreService>;

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();

    // Get the mocked instance that will be used by the function
    mockFirestoreService = new FirestoreService() as jest.Mocked<FirestoreService>;
  });

  it("should successfully validate first completion with rank calculation", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 3;
    const completionTime = 45000;

    // Mock no existing completion
    mockFirestoreService.getDocument.mockResolvedValue(null);

    // Mock setDocument (save completion)
    mockFirestoreService.setDocument.mockResolvedValue(undefined);

    // Mock queryDocuments to return 3 entries (user is 2nd)
    const mockEntries: DailyChallengeCompletion[] = [
      {
        userId: "user999",
        dateId,
        stars: 3,
        completionTime: 30000,
        completedAt: {},
      },
      {
        userId,
        dateId,
        stars,
        completionTime,
        completedAt: {},
      },
      {
        userId: "user888",
        dateId,
        stars: 2,
        completionTime: 20000,
        completedAt: {},
      },
    ];
    mockFirestoreService.queryDocuments.mockResolvedValue(mockEntries);

    // Call function
    const result = await validateDailyChallengeCompletionHandler(
      {
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      },
      mockFirestoreService
    );

    // Assertions
    expect(result).toEqual({
      success: true,
      rank: 2,
      totalPlayers: 3,
    });

    expect(mockFirestoreService.getDocument).toHaveBeenCalledWith(
      `dailyChallenges/${dateId}/entries`,
      userId
    );

    expect(mockFirestoreService.setDocument).toHaveBeenCalledWith(
      `dailyChallenges/${dateId}/entries`,
      userId,
      expect.objectContaining({
        userId,
        dateId,
        stars,
        completionTime,
      })
    );

    expect(mockFirestoreService.queryDocuments).toHaveBeenCalledWith(
      `dailyChallenges/${dateId}/entries`,
      [
        { field: "stars", direction: "desc" },
        { field: "completionTime", direction: "asc" },
      ]
    );
  });

  it("should reject duplicate completion attempts", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 3;
    const completionTime = 45000;

    // Mock existing completion
    const existingCompletion: DailyChallengeCompletion = {
      userId,
      dateId,
      stars: 2,
      completionTime: 60000,
      completedAt: {},
    };
    mockFirestoreService.getDocument.mockResolvedValue(existingCompletion);

    // Call function and expect HttpsError to be thrown
    await expect(
      validateDailyChallengeCompletionHandler(
        {
          auth: { uid: userId },
          data: { dateId, stars, completionTime },
        },
        mockFirestoreService
      )
    ).rejects.toThrow("User has already completed this daily challenge");

    // setDocument should NOT be called
    expect(mockFirestoreService.setDocument).not.toHaveBeenCalled();
  });

  it("should reject invalid stars (below 0)", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = -1;
    const completionTime = 45000;

    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      })
    ).rejects.toThrow("stars must be between 0 and 3");
  });

  it("should reject invalid stars (above 3)", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 4;
    const completionTime = 45000;

    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      })
    ).rejects.toThrow("stars must be between 0 and 3");
  });

  it("should reject suspicious completion times (< 1000ms)", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 3;
    const completionTime = 500;

    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      })
    ).rejects.toThrow("completionTime must be at least 1000ms");
  });

  it("should reject unauthenticated users", async () => {
    await expect(
      validateDailyChallengeCompletionHandler({
        auth: null,
        data: {
          dateId: "2026-01-30",
          stars: 3,
          completionTime: 45000,
        },
      })
    ).rejects.toThrow("User must be authenticated");
  });

  it("should correctly calculate rank with multiple users", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 2;
    const completionTime = 50000;

    // Mock no existing completion
    mockFirestoreService.getDocument.mockResolvedValue(null);
    mockFirestoreService.setDocument.mockResolvedValue(undefined);

    // Mock queryDocuments to return 5 entries (user is 4th)
    const mockEntries: DailyChallengeCompletion[] = [
      { userId: "user1", dateId, stars: 3, completionTime: 30000, completedAt: {} },
      { userId: "user2", dateId, stars: 3, completionTime: 35000, completedAt: {} },
      { userId: "user3", dateId, stars: 2, completionTime: 40000, completedAt: {} },
      { userId, dateId, stars, completionTime, completedAt: {} },
      { userId: "user5", dateId, stars: 1, completionTime: 25000, completedAt: {} },
    ];
    mockFirestoreService.queryDocuments.mockResolvedValue(mockEntries);

    const result = await validateDailyChallengeCompletionHandler(
      {
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      },
      mockFirestoreService
    );

    expect(result).toEqual({
      success: true,
      rank: 4,
      totalPlayers: 5,
    });
  });

  it("should save completion with 'completionTime' field (not 'completionTimeMs')", async () => {
    const userId = "user123";
    const dateId = "2026-01-30";
    const stars = 3;
    const completionTime = 45000;

    mockFirestoreService.getDocument.mockResolvedValue(null);
    mockFirestoreService.setDocument.mockResolvedValue(undefined);
    mockFirestoreService.queryDocuments.mockResolvedValue([
      { userId, dateId, stars, completionTime, completedAt: {} },
    ]);

    await validateDailyChallengeCompletionHandler(
      {
        auth: { uid: userId },
        data: { dateId, stars, completionTime },
      },
      mockFirestoreService
    );

    // Verify the saved document uses 'completionTime' field name
    const savedDoc = mockFirestoreService.setDocument.mock.calls[0][2];
    expect(savedDoc).toHaveProperty("completionTime", 45000);
    expect(savedDoc).not.toHaveProperty("completionTimeMs");

    // Verify leaderboard query uses 'completionTime' field name
    const queryArgs = mockFirestoreService.queryDocuments.mock.calls[0][1];
    const timeField = queryArgs.find((f: any) => f.field === "completionTime");
    expect(timeField).toBeDefined();
    expect(queryArgs.find((f: any) => f.field === "completionTimeMs")).toBeUndefined();
  });

  it("should validate required fields", async () => {
    const userId = "user123";

    // Missing dateId
    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { stars: 3, completionTime: 45000 } as any,
      })
    ).rejects.toThrow("dateId is required");

    // Missing stars
    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { dateId: "2026-01-30", completionTime: 45000 } as any,
      })
    ).rejects.toThrow("stars is required");

    // Missing completionTime
    await expect(
      validateDailyChallengeCompletionHandler({
        auth: { uid: userId },
        data: { dateId: "2026-01-30", stars: 3 } as any,
      })
    ).rejects.toThrow("completionTime is required");
  });
});
