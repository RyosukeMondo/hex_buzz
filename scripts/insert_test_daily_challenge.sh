#!/bin/bash

# Simple script to insert test data into daily challenge leaderboard using Firebase CLI

DATE_ID=$(date -u +"%Y-%m-%d")
USER_ID="test-user-$(date +%s)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "🧪 Inserting test daily challenge leaderboard entry"
echo "=================================================="
echo "📅 Date ID: $DATE_ID"
echo "👤 User ID: $USER_ID"
echo "🕐 Timestamp: $TIMESTAMP"
echo ""

# First, ensure the daily challenge document exists
echo "Step 1: Creating/checking daily challenge..."
firebase firestore:set "dailyChallenges/$DATE_ID" <<EOF
{
  "id": "$DATE_ID",
  "createdAt": "$TIMESTAMP",
  "level": {
    "id": "daily-$DATE_ID",
    "gridSize": 8,
    "difficulty": "medium",
    "cells": [],
    "startPosition": { "q": 0, "r": 0 },
    "endPosition": { "q": 7, "r": 7 }
  },
  "completionCount": 0,
  "notificationSent": false
}
EOF

echo ""
echo "Step 2: Inserting test leaderboard entry..."

# Insert a test completion
firebase firestore:set "dailyChallenges/$DATE_ID/completions/$USER_ID" <<EOF
{
  "userId": "$USER_ID",
  "username": "Test User",
  "stars": 3,
  "completionTimeMs": 45000,
  "completedAt": "$TIMESTAMP"
}
EOF

echo ""
echo "Step 3: Querying leaderboard..."
firebase firestore:get "dailyChallenges/$DATE_ID/completions"

echo ""
echo "✅ Test complete!"
echo ""
echo "To view in your app, check the daily challenge screen."
echo "To delete test data:"
echo "  firebase firestore:delete dailyChallenges/$DATE_ID/completions/$USER_ID"
