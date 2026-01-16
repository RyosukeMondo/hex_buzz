#!/bin/bash
# Firestore Security Rules Testing Script
# Uses Firebase Emulator Suite to test security rules in isolation
#
# Prerequisites:
# 1. Firebase CLI installed: npm install -g firebase-tools
# 2. Firebase emulators initialized: firebase init emulators
# 3. Node.js installed for running test scripts
#
# Usage:
#   ./test/security/firestore_security_emulator_test.sh

set -e  # Exit on error

echo "🔒 Firestore Security Rules Testing"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Error: Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

echo -e "${GREEN}✓${NC} Firebase CLI found"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js not found${NC}"
    echo "Install Node.js from: https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Node.js found"

# Check if firestore.rules exists
if [ ! -f "firestore.rules" ]; then
    echo -e "${RED}❌ Error: firestore.rules not found${NC}"
    echo "Run this script from the project root directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} firestore.rules found"

# Create security test directory if it doesn't exist
mkdir -p test/security/emulator_tests

# Create package.json for emulator tests if it doesn't exist
if [ ! -f "test/security/emulator_tests/package.json" ]; then
    echo -e "${YELLOW}Creating package.json for emulator tests...${NC}"
    cat > test/security/emulator_tests/package.json << 'EOF'
{
  "name": "firestore-security-tests",
  "version": "1.0.0",
  "description": "Security tests for Firestore rules using Firebase Emulator",
  "scripts": {
    "test": "mocha --exit"
  },
  "dependencies": {
    "@firebase/rules-unit-testing": "^3.0.0",
    "mocha": "^10.2.0"
  }
}
EOF
fi

# Install dependencies if needed
if [ ! -d "test/security/emulator_tests/node_modules" ]; then
    echo -e "${YELLOW}Installing test dependencies...${NC}"
    cd test/security/emulator_tests
    npm install
    cd ../../..
fi

echo -e "${GREEN}✓${NC} Test dependencies ready"

# Create the actual test file
echo -e "${YELLOW}Creating security test suite...${NC}"
cat > test/security/emulator_tests/security_rules.test.js << 'EOF'
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { setLogLevel } = require('@firebase/rules-unit-testing');
const fs = require('fs');

// Set log level to error to reduce noise
setLogLevel('error');

describe('Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    // Initialize test environment
    testEnv = await initializeTestEnvironment({
      projectId: 'hexbuzz-test',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  describe('Users Collection', () => {
    it('allows authenticated users to read any user profile', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('bob').set({
          uid: 'bob',
          displayName: 'Bob',
          email: 'bob@example.com',
          totalStars: 100,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        });
      });

      await assertSucceeds(alice.firestore().collection('users').doc('bob').get());
    });

    it('blocks unauthenticated users from reading profiles', async () => {
      const unauth = testEnv.unauthenticatedContext();
      await assertFails(unauth.firestore().collection('users').doc('alice').get());
    });

    it('allows users to create their own profile with valid data', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        alice.firestore().collection('users').doc('alice').set({
          uid: 'alice',
          displayName: 'Alice',
          email: 'alice@example.com',
          totalStars: 0,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        })
      );
    });

    it('blocks users from creating profiles for other users', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('users').doc('bob').set({
          uid: 'bob',
          displayName: 'Bob',
          totalStars: 0,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        })
      );
    });

    it('blocks profile creation without valid timestamps', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('users').doc('alice').set({
          uid: 'alice',
          displayName: 'Alice',
          totalStars: 0,
          // Missing createdAt and lastLoginAt
        })
      );
    });

    it('allows users to update their own profile', async () => {
      const alice = testEnv.authenticatedContext('alice');
      // Create profile first
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('alice').set({
          uid: 'alice',
          displayName: 'Alice',
          totalStars: 0,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        });
      });

      await assertSucceeds(
        alice.firestore().collection('users').doc('alice').update({
          displayName: 'Alice Updated',
          lastLoginAt: new Date(),
        })
      );
    });

    it('blocks users from updating other users profiles', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('bob').set({
          uid: 'bob',
          displayName: 'Bob',
          totalStars: 0,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        });
      });

      await assertFails(
        alice.firestore().collection('users').doc('bob').update({
          displayName: 'Hacked',
        })
      );
    });

    it('blocks profile deletion', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('alice').set({
          uid: 'alice',
          displayName: 'Alice',
        });
      });

      await assertFails(alice.firestore().collection('users').doc('alice').delete());
    });
  });

  describe('Leaderboard Collection', () => {
    it('allows authenticated users to read leaderboard', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('leaderboard').doc('bob').set({
          userId: 'bob',
          username: 'Bob',
          totalStars: 150,
          rank: 1,
        });
      });

      await assertSucceeds(alice.firestore().collection('leaderboard').doc('bob').get());
    });

    it('blocks unauthenticated users from reading leaderboard', async () => {
      const unauth = testEnv.unauthenticatedContext();
      await assertFails(unauth.firestore().collection('leaderboard').doc('bob').get());
    });

    it('blocks clients from writing to leaderboard', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('leaderboard').doc('alice').set({
          userId: 'alice',
          totalStars: 9999,
          rank: 1,
        })
      );
    });
  });

  describe('Daily Challenges Collection', () => {
    it('allows authenticated users to read daily challenges', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('dailyChallenges').doc('2026-01-17').set({
          date: new Date('2026-01-17'),
          completionCount: 42,
        });
      });

      await assertSucceeds(
        alice.firestore().collection('dailyChallenges').doc('2026-01-17').get()
      );
    });

    it('blocks clients from creating daily challenges', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('dailyChallenges').doc('2026-01-17').set({
          date: new Date('2026-01-17'),
          completionCount: 0,
        })
      );
    });

    it('allows authenticated users to read challenge entries', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context
          .firestore()
          .collection('dailyChallenges')
          .doc('2026-01-17')
          .collection('entries')
          .doc('bob')
          .set({
            userId: 'bob',
            username: 'Bob',
            stars: 3,
            completionTime: 12345,
          });
      });

      await assertSucceeds(
        alice
          .firestore()
          .collection('dailyChallenges')
          .doc('2026-01-17')
          .collection('entries')
          .doc('bob')
          .get()
      );
    });

    it('blocks clients from writing challenge entries', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice
          .firestore()
          .collection('dailyChallenges')
          .doc('2026-01-17')
          .collection('entries')
          .doc('alice')
          .set({
            userId: 'alice',
            stars: 3,
            completionTime: 12345,
          })
      );
    });
  });

  describe('Score Submissions Collection', () => {
    it('allows users to submit their own scores with valid data', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 3,
          time: 12345,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks users from submitting scores for other users', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'bob',
          stars: 3,
          time: 12345,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks score submissions with invalid star count (>3)', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 999,
          time: 12345,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks score submissions with negative star count', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: -1,
          time: 12345,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks score submissions with invalid time (zero)', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 3,
          time: 0,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks score submissions with negative time', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        alice.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 3,
          time: -100,
          totalStars: 150,
          submittedAt: new Date(),
        })
      );
    });

    it('blocks reading score submissions', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('scoreSubmissions').doc('test').set({
          userId: 'alice',
          stars: 3,
          time: 12345,
        });
      });

      await assertFails(
        alice.firestore().collection('scoreSubmissions').doc('test').get()
      );
    });

    it('blocks updating score submissions', async () => {
      const alice = testEnv.authenticatedContext('alice');
      let docId;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 3,
          time: 12345,
          totalStars: 150,
          submittedAt: new Date(),
        });
        docId = ref.id;
      });

      await assertFails(
        alice.firestore().collection('scoreSubmissions').doc(docId).update({
          stars: 1,
        })
      );
    });

    it('blocks deleting score submissions', async () => {
      const alice = testEnv.authenticatedContext('alice');
      let docId;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const ref = await context.firestore().collection('scoreSubmissions').add({
          userId: 'alice',
          stars: 3,
          time: 12345,
        });
        docId = ref.id;
      });

      await assertFails(
        alice.firestore().collection('scoreSubmissions').doc(docId).delete()
      );
    });
  });
});
EOF

echo -e "${GREEN}✓${NC} Security test suite created"

# Start emulator and run tests
echo ""
echo -e "${YELLOW}Starting Firebase Emulator...${NC}"
echo "This will start the Firestore emulator on port 8080"
echo ""

# Run emulator with tests
cd test/security/emulator_tests
firebase emulators:exec --only firestore "npm test" --project hexbuzz-test || {
    echo ""
    echo -e "${RED}❌ Security tests failed${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Firestore emulator not configured (run: firebase init emulators)"
    echo "2. Port 8080 already in use"
    echo "3. Security rules have errors"
    echo ""
    exit 1
}

echo ""
echo -e "${GREEN}✅ All security tests passed!${NC}"
echo ""
echo "Security rules are properly configured to:"
echo "  ✓ Enforce authentication"
echo "  ✓ Protect user data"
echo "  ✓ Prevent unauthorized writes to computed data"
echo "  ✓ Validate data types and constraints"
echo ""
