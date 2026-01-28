#!/bin/bash
# Test script for daily challenge and notifications

echo "🐝 Testing Daily Challenge Generation..."
echo ""

# Test 1: Generate a daily challenge
echo "1️⃣ Generating daily challenge..."
RESPONSE=$(curl -s -X POST http://127.0.0.1:5001/hexbuzz-game/us-central1/manualGenerateChallenge)
echo "Response: $RESPONSE"
echo ""

# Test 2: Send push notifications
echo "2️⃣ Sending push notifications..."
TODAY=$(date -u +%Y-%m-%d)
RESPONSE=$(curl -s -X POST http://127.0.0.1:5001/hexbuzz-game/us-central1/manualSendNotification \
  -H "Content-Type: application/json" \
  -d "{\"challengeId\": \"$TODAY\"}")
echo "Response: $RESPONSE"
echo ""

echo "✅ Test complete!"
echo ""
echo "📊 View results:"
echo "   Emulator UI: http://127.0.0.1:4000"
echo "   Firestore:   http://127.0.0.1:4000/firestore"
echo "   Functions:   http://127.0.0.1:4000/functions"
