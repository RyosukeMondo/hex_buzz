#!/bin/bash

# Insert test leaderboard entry using Firebase CLI

PROJECT_ID="hexbuzz-game"
DATE_ID=$(date -u +"%Y-%m-%d")
USER_ID="test-user-$(date +%s)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "📝 Inserting test leaderboard entry..."
echo "Date: $DATE_ID"
echo "User: $USER_ID"
echo ""

# Using Firebase CLI to set the document
firebase firestore:set --project="$PROJECT_ID" \
  "dailyChallenges/$DATE_ID/completions/$USER_ID" \
  --data "{
    \"userId\": \"$USER_ID\",
    \"username\": \"Test Player\",
    \"stars\": 3,
    \"completionTimeMs\": 45000,
    \"completedAt\": \"$TIMESTAMP\"
  }" \
  --yes

echo ""
echo "✅ Test entry inserted!"
echo "Refresh your app to see it."
