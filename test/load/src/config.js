/**
 * Load testing configuration for HexBuzz
 */

export const defaultConfig = {
  // Firebase configuration
  firebaseProject: process.env.FIREBASE_PROJECT || 'hexbuzz-staging',
  useEmulator: process.env.USE_EMULATOR === 'true',
  emulatorHost: 'localhost',
  emulatorFirestorePort: 8080,
  emulatorFunctionsPort: 5001,
  emulatorAuthPort: 9099,

  // Test configuration
  defaultUsers: 100,
  defaultDuration: 60, // seconds
  defaultRampUp: 10, // seconds

  // Performance targets (SLOs)
  targets: {
    scoreSubmission: {
      p95Latency: 2000, // ms
      p99Latency: 5000, // ms
      errorRate: 0.01, // 1%
    },
    leaderboardQuery: {
      p95Latency: 2000, // ms
      p99Latency: 3000, // ms
      errorRate: 0.01, // 1%
    },
    dailyChallenge: {
      p95Latency: 3000, // ms
      p99Latency: 5000, // ms
      errorRate: 0.01, // 1%
    },
    notification: {
      deliveryRate: 0.95, // 95%
      p95Latency: 5000, // ms
    },
  },

  // Rate limiting
  rateLimit: {
    scoreSubmission: {
      perUserPerMinute: 10,
      minIntervalMs: 1000,
    },
    leaderboardQuery: {
      perUserPerMinute: 60,
      minIntervalMs: 100,
    },
  },

  // Test data generation
  testData: {
    usernamePrefix: 'loadtest_user_',
    levelIds: Array.from({ length: 50 }, (_, i) => i + 1),
    minStars: 1,
    maxStars: 3,
    minCompletionTime: 10000, // ms
    maxCompletionTime: 300000, // ms
  },

  // Reporting
  reporting: {
    enableProgressBar: true,
    enableVerboseLogging: false,
    saveToFile: true,
    reportDirectory: './reports',
  },
};

/**
 * Merge user-provided config with defaults
 */
export function mergeConfig(userConfig = {}) {
  return {
    ...defaultConfig,
    ...userConfig,
    targets: {
      ...defaultConfig.targets,
      ...(userConfig.targets || {}),
    },
    rateLimit: {
      ...defaultConfig.rateLimit,
      ...(userConfig.rateLimit || {}),
    },
    testData: {
      ...defaultConfig.testData,
      ...(userConfig.testData || {}),
    },
    reporting: {
      ...defaultConfig.reporting,
      ...(userConfig.reporting || {}),
    },
  };
}
