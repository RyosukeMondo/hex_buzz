#!/bin/bash
# Test direct database write for daily challenge entry
# This verifies the database accepts writes

echo "📝 Testing Direct Daily Challenge Entry Submission"
echo "================================================="
echo ""

TODAY=$(date -u +%Y-%m-%d)
TEST_USER_ID="test-user-direct-$(date +%s)"

echo "📅 Date: $TODAY"
echo "👤 Test User ID: $TEST_USER_ID"
echo ""

# Use Firebase REST API to write directly
curl -X PUT \
  "https://firestore.googleapis.com/v1/projects/hexbuzz-game/databases/(default)/documents/dailyChallenges/$TODAY/entries/$TEST_USER_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "userId": {"stringValue": "'$TEST_USER_ID'"},
      "username": {"stringValue": "Direct Test User"},
      "stars": {"integerValue": "3"},
      "completionTime": {"integerValue": "12345"},
      "totalStars": {"integerValue": "999"},
      "completedAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
    }
  }' | jq '.'

echo ""
echo "✅ Test entry submitted. Check diagnostics API to verify:"
echo "   curl https://us-central1-hexbuzz-game.cloudfunctions.net/apiDiagnostics | jq '.tests.leaderboardRead'"
