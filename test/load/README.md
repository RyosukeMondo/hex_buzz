# Load Testing Suite for HexBuzz

This directory contains load testing scripts for Firebase Cloud Functions and Firestore operations.

## Overview

The load testing suite simulates concurrent users performing various operations to ensure the system can handle production-level traffic and scale appropriately.

## Prerequisites

1. **Node.js**: Version 18 or higher
2. **Firebase Project**: A staging/test Firebase project (DO NOT use production)
3. **Service Account Key**: Download from Firebase Console > Project Settings > Service Accounts

## Setup

1. Install dependencies:
```bash
cd test/load
npm install
```

2. Set up Firebase credentials:
```bash
# Copy your service account key to this directory
cp /path/to/serviceAccountKey.json ./serviceAccountKey.json

# Or set the environment variable
export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
```

3. Configure test parameters in `config.js` or use command-line arguments

## Test Scenarios

### 1. Score Submission Load Test
Simulates concurrent users submitting scores to trigger the `onScoreUpdate` Cloud Function.

```bash
npm run test:score-submission -- --users 1000 --duration 60
```

**Tests:**
- Concurrent score submissions
- Cloud Function triggers and execution
- Firestore writes and updates
- Rank recomputation under load
- Notification delivery

**Metrics:**
- Requests per second
- Average response time
- Error rate
- P95/P99 latency
- Function execution time
- Firestore read/write operations

### 2. Leaderboard Query Load Test
Simulates concurrent users querying the leaderboard with pagination.

```bash
npm run test:leaderboard -- --users 500 --queries-per-user 10
```

**Tests:**
- Concurrent leaderboard queries
- Pagination performance
- Composite index efficiency
- Read operations under load

**Metrics:**
- Query response time
- Queries per second
- Cache hit rate
- P95/P99 latency

### 3. Daily Challenge Load Test
Simulates the daily challenge generation and simultaneous user completions.

```bash
npm run test:daily-challenge -- --users 800 --concurrent 100
```

**Tests:**
- Daily challenge generation
- Concurrent completion submissions
- Leaderboard updates
- Notification topic messaging

**Metrics:**
- Challenge generation time
- Completion submission throughput
- Notification delivery rate
- Error rate

### 4. Notification Delivery Load Test
Tests notification delivery at scale for daily challenges and rank changes.

```bash
npm run test:notifications -- --subscribers 5000
```

**Tests:**
- FCM topic message delivery
- Device token subscriptions
- Notification throughput
- Delivery success rate

**Metrics:**
- Messages per second
- Delivery latency
- Success/failure rate
- Token subscription time

### 5. Concurrent Users Test
Simulates a realistic mix of operations from concurrent users.

```bash
npm run test:concurrent -- --users 1000 --duration 300
```

**Tests:**
- Mixed workload (reads, writes, queries)
- Realistic user behavior patterns
- System stability under sustained load
- Resource utilization

**Metrics:**
- Overall throughput
- Operation mix breakdown
- Error rates by operation type
- System resource usage

## Command-Line Arguments

All test scripts support the following arguments:

- `--users <number>`: Number of concurrent users (default: 100)
- `--duration <seconds>`: Test duration in seconds (default: 60)
- `--ramp-up <seconds>`: Ramp-up time to reach target users (default: 10)
- `--firebase-project <id>`: Firebase project ID
- `--emulator`: Use Firebase Emulator Suite (recommended for local testing)
- `--verbose`: Enable detailed logging
- `--report <path>`: Save test report to file

## Performance Targets

Based on requirements, the system should meet these SLOs:

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Score submission response time | < 2s (P95) | < 5s (P99) |
| Leaderboard query time | < 2s (P95) | < 3s (P99) |
| Notification delivery | > 95% success | > 90% minimum |
| Concurrent users supported | 1000+ | 500 minimum |
| Cloud Function execution time | < 5s (P95) | < 10s (P99) |
| Error rate | < 1% | < 5% maximum |

## Running Tests

### Quick Start - All Tests
```bash
npm run test:all
```

### Individual Tests
```bash
# Test score submissions with 1000 users for 60 seconds
npm run test:score-submission -- --users 1000 --duration 60

# Test leaderboard queries with 500 users
npm run test:leaderboard -- --users 500

# Test daily challenge with 800 users
npm run test:daily-challenge -- --users 800
```

### Using Firebase Emulator (Recommended for Local Testing)
```bash
# Start Firebase Emulator Suite in another terminal
cd ../../
firebase emulators:start

# Run tests against emulator
npm run test:concurrent -- --users 100 --emulator
```

### Production-Like Load Test (Use Staging Project!)
```bash
# WARNING: Use a dedicated staging project, NOT production!
npm run test:concurrent -- \
  --users 1000 \
  --duration 300 \
  --ramp-up 30 \
  --firebase-project hexbuzz-staging \
  --report ./reports/load-test-$(date +%Y%m%d-%H%M%S).json
```

## Test Reports

Test results are saved in JSON format and include:

- Test configuration (users, duration, etc.)
- Summary metrics (throughput, latency, errors)
- Detailed timing data for each operation
- Error breakdown by type
- Resource utilization stats
- Recommendations for optimization

Example report location:
```
test/load/reports/load-test-20260117-120000.json
```

## Monitoring During Tests

Monitor these Firebase Console sections during load tests:

1. **Functions Dashboard**: Function invocations, execution time, errors
2. **Firestore Usage**: Read/write operations, index usage
3. **Cloud Messaging**: Message delivery rates
4. **Performance Monitoring**: App performance metrics

## Cost Estimation

Load testing can incur Firebase costs. Estimate before running:

**Firestore Costs:**
- Document reads: $0.06 per 100K
- Document writes: $0.18 per 100K
- 1000 users × 60s × 1 write/s = 60K writes = ~$0.11

**Cloud Functions Costs:**
- Invocations: $0.40 per million
- Compute time: ~$0.0000025 per GB-second
- 60K invocations = ~$0.02

**Total for 1000-user 60s test: ~$0.15-0.50**

Use Firebase Emulator for free local testing!

## Interpreting Results

### Good Results
- P95 latency < 2s for queries
- P99 latency < 5s for writes
- Error rate < 1%
- Linear scaling up to target users

### Warning Signs
- Latency increases exponentially with users
- Error rate > 5%
- Function timeouts or cold starts
- Firestore quota errors

### Action Items
If tests show performance issues:

1. **Slow queries**: Add/optimize Firestore indexes
2. **High write latency**: Implement batching or queuing
3. **Function timeouts**: Increase timeout or optimize code
4. **Cold starts**: Keep functions warm with scheduled pings
5. **Rate limiting**: Implement client-side throttling

## Troubleshooting

### Error: "PERMISSION_DENIED"
- Check Firestore security rules
- Verify service account has correct permissions
- Ensure authentication is properly configured

### Error: "QUOTA_EXCEEDED"
- Reduce concurrent users or test duration
- Increase Firebase quotas in console
- Use Firebase Emulator for unlimited testing

### Error: "DEADLINE_EXCEEDED"
- Reduce load or increase Cloud Function timeout
- Optimize slow Firestore queries
- Check for N+1 query problems

### Slow Performance
- Verify composite indexes are deployed
- Check for missing indexes in Firestore console
- Monitor Cloud Function memory usage
- Review batching and caching strategies

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Load Tests

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        working-directory: test/load
        run: npm install

      - name: Start Firebase Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore,functions &
          sleep 10

      - name: Run load tests
        working-directory: test/load
        run: npm run test:all -- --emulator --users 500 --duration 60
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: load-test-results
          path: test/load/reports/
```

## Best Practices

1. **Always use a staging project** for load tests, never production
2. **Start small** (10-100 users) and gradually increase
3. **Monitor costs** during tests to avoid surprises
4. **Clean up test data** after tests complete
5. **Run regularly** to catch performance regressions early
6. **Document baselines** to track performance over time
7. **Test realistic scenarios** matching actual user behavior
8. **Use emulator** for development and CI/CD

## Related Documentation

- [Firebase Performance Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Cloud Functions Performance Tips](https://firebase.google.com/docs/functions/tips)
- [Firestore Query Performance](https://firebase.google.com/docs/firestore/query-data/queries)
- Project performance requirements: `docs/requirements.md`
- Security testing: `test/security/SECURITY_TESTING_REPORT.md`
