/**
 * Utility functions for load testing
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Calculate statistics from an array of numbers
 */
export function calculateStats(values) {
  if (values.length === 0) {
    return {
      min: 0,
      max: 0,
      mean: 0,
      median: 0,
      p95: 0,
      p99: 0,
      stdDev: 0,
    };
  }

  const sorted = [...values].sort((a, b) => a - b);
  const sum = values.reduce((acc, val) => acc + val, 0);
  const mean = sum / values.length;

  // Calculate standard deviation
  const squaredDiffs = values.map(val => Math.pow(val - mean, 2));
  const variance = squaredDiffs.reduce((acc, val) => acc + val, 0) / values.length;
  const stdDev = Math.sqrt(variance);

  return {
    min: sorted[0],
    max: sorted[sorted.length - 1],
    mean: mean,
    median: sorted[Math.floor(sorted.length / 2)],
    p95: sorted[Math.floor(sorted.length * 0.95)],
    p99: sorted[Math.floor(sorted.length * 0.99)],
    stdDev: stdDev,
    count: values.length,
  };
}

/**
 * Generate a random integer between min and max (inclusive)
 */
export function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Generate a random item from an array
 */
export function randomItem(array) {
  return array[Math.floor(Math.random() * array.length)];
}

/**
 * Sleep for a specified number of milliseconds
 */
export function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Create a rate limiter that ensures minimum interval between operations
 */
export function createRateLimiter(minIntervalMs) {
  let lastExecutionTime = 0;

  return async function() {
    const now = Date.now();
    const timeSinceLastExecution = now - lastExecutionTime;

    if (timeSinceLastExecution < minIntervalMs) {
      await sleep(minIntervalMs - timeSinceLastExecution);
    }

    lastExecutionTime = Date.now();
  };
}

/**
 * Chunk an array into smaller arrays
 */
export function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * Run operations in parallel with a concurrency limit
 */
export async function parallelLimit(operations, limit) {
  const results = [];
  const executing = [];

  for (const operation of operations) {
    const promise = Promise.resolve().then(operation);
    results.push(promise);

    if (limit <= operations.length) {
      const e = promise.then(() => executing.splice(executing.indexOf(e), 1));
      executing.push(e);

      if (executing.length >= limit) {
        await Promise.race(executing);
      }
    }
  }

  return Promise.all(results);
}

/**
 * Save test results to a JSON file
 */
export function saveResults(results, reportDirectory = './reports') {
  const reportsDir = path.resolve(__dirname, '..', reportDirectory);

  // Create reports directory if it doesn't exist
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `load-test-${results.testName}-${timestamp}.json`;
  const filepath = path.join(reportsDir, filename);

  fs.writeFileSync(filepath, JSON.stringify(results, null, 2));

  return filepath;
}

/**
 * Format duration in seconds to human-readable string
 */
export function formatDuration(seconds) {
  if (seconds < 60) {
    return `${seconds}s`;
  }
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}m ${remainingSeconds}s`;
}

/**
 * Format bytes to human-readable string
 */
export function formatBytes(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
}

/**
 * Create a progress tracker for long-running operations
 */
export class ProgressTracker {
  constructor(total, label = 'Progress') {
    this.total = total;
    this.current = 0;
    this.label = label;
    this.startTime = Date.now();
  }

  increment(amount = 1) {
    this.current += amount;
    this.logProgress();
  }

  logProgress() {
    const percentage = ((this.current / this.total) * 100).toFixed(1);
    const elapsed = ((Date.now() - this.startTime) / 1000).toFixed(1);
    const rate = (this.current / elapsed).toFixed(2);

    process.stdout.write(
      `\r${this.label}: ${this.current}/${this.total} (${percentage}%) - ${rate} ops/s - ${elapsed}s elapsed`
    );

    if (this.current >= this.total) {
      process.stdout.write('\n');
    }
  }

  finish() {
    this.current = this.total;
    this.logProgress();
  }
}

/**
 * Measure execution time of an async function
 */
export async function measureTime(fn) {
  const startTime = Date.now();
  try {
    const result = await fn();
    const duration = Date.now() - startTime;
    return { success: true, duration, result };
  } catch (error) {
    const duration = Date.now() - startTime;
    return { success: false, duration, error };
  }
}

/**
 * Generate a realistic user session with mixed operations
 */
export function* generateUserSession(config) {
  const operations = [
    { type: 'leaderboard_query', weight: 5 },
    { type: 'score_submission', weight: 2 },
    { type: 'daily_challenge_view', weight: 1 },
    { type: 'daily_challenge_complete', weight: 1 },
  ];

  const totalWeight = operations.reduce((sum, op) => sum + op.weight, 0);

  while (true) {
    // Weighted random selection
    const random = Math.random() * totalWeight;
    let cumulative = 0;

    for (const operation of operations) {
      cumulative += operation.weight;
      if (random < cumulative) {
        yield operation.type;
        break;
      }
    }

    // Random delay between operations (simulate user thinking time)
    const thinkTime = randomInt(1000, 5000);
    yield { type: 'sleep', duration: thinkTime };
  }
}

/**
 * Validate test results against SLOs
 */
export function validateSLOs(stats, targets) {
  const violations = [];

  if (stats.p95 > targets.p95Latency) {
    violations.push({
      metric: 'P95 Latency',
      expected: targets.p95Latency,
      actual: stats.p95,
      severity: 'warning',
    });
  }

  if (stats.p99 > targets.p99Latency) {
    violations.push({
      metric: 'P99 Latency',
      expected: targets.p99Latency,
      actual: stats.p99,
      severity: 'critical',
    });
  }

  if (stats.errorRate > targets.errorRate) {
    violations.push({
      metric: 'Error Rate',
      expected: `< ${targets.errorRate * 100}%`,
      actual: `${(stats.errorRate * 100).toFixed(2)}%`,
      severity: 'critical',
    });
  }

  return {
    passed: violations.length === 0,
    violations,
  };
}

/**
 * Generate test report summary
 */
export function generateReportSummary(results) {
  const summary = {
    testName: results.testName,
    timestamp: results.timestamp,
    duration: results.duration,
    configuration: results.configuration,
    totalOperations: results.totalOperations,
    successfulOperations: results.successfulOperations,
    failedOperations: results.failedOperations,
    errorRate: (results.failedOperations / results.totalOperations * 100).toFixed(2) + '%',
    throughput: (results.totalOperations / results.duration).toFixed(2) + ' ops/s',
    latencyStats: results.latencyStats,
    sloValidation: results.sloValidation,
  };

  return summary;
}

/**
 * Print colored console output
 */
export function colorize(text, color) {
  const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
  };

  return `${colors[color] || colors.reset}${text}${colors.reset}`;
}

/**
 * Print test results summary to console
 */
export function printResultsSummary(results) {
  console.log('\n' + '='.repeat(80));
  console.log(colorize(`  Load Test Results: ${results.testName}`, 'cyan'));
  console.log('='.repeat(80));

  console.log('\nConfiguration:');
  console.log(`  Users: ${results.configuration.users}`);
  console.log(`  Duration: ${formatDuration(results.duration)}`);
  console.log(`  Total Operations: ${results.totalOperations}`);

  console.log('\nPerformance:');
  console.log(`  Throughput: ${(results.totalOperations / results.duration).toFixed(2)} ops/s`);
  console.log(`  Success Rate: ${((results.successfulOperations / results.totalOperations) * 100).toFixed(2)}%`);
  console.log(`  Error Rate: ${((results.failedOperations / results.totalOperations) * 100).toFixed(2)}%`);

  console.log('\nLatency Statistics:');
  console.log(`  Min: ${results.latencyStats.min.toFixed(2)} ms`);
  console.log(`  Max: ${results.latencyStats.max.toFixed(2)} ms`);
  console.log(`  Mean: ${results.latencyStats.mean.toFixed(2)} ms`);
  console.log(`  Median: ${results.latencyStats.median.toFixed(2)} ms`);
  console.log(`  P95: ${results.latencyStats.p95.toFixed(2)} ms`);
  console.log(`  P99: ${results.latencyStats.p99.toFixed(2)} ms`);

  if (results.sloValidation) {
    console.log('\nSLO Validation:');
    if (results.sloValidation.passed) {
      console.log(colorize('  ✓ All SLOs passed', 'green'));
    } else {
      console.log(colorize('  ✗ SLO violations detected:', 'red'));
      results.sloValidation.violations.forEach(v => {
        const color = v.severity === 'critical' ? 'red' : 'yellow';
        console.log(colorize(`    - ${v.metric}: Expected ${v.expected}, Got ${v.actual}`, color));
      });
    }
  }

  console.log('\n' + '='.repeat(80) + '\n');
}
