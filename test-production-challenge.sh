#!/bin/bash
# Test daily challenge with production Firestore (no Cloud Functions deployment needed)

API_KEY="AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc"
PROJECT_ID="hexbuzz-game"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

echo "🐝 Testing Production Daily Challenge..."
echo ""

# Get today's date
TODAY=$(date -u +%Y-%m-%d)
echo "📅 Today: $TODAY"
echo ""

# Check if challenge exists
echo "1️⃣ Checking for existing challenge..."
CHALLENGE=$(curl -s "${BASE_URL}/dailyChallenges/${TODAY}?key=${API_KEY}")

if echo "$CHALLENGE" | grep -q '"name"'; then
  echo "✅ Challenge exists for today!"
  echo "$CHALLENGE" | jq -r '.fields.id.stringValue, .fields.completionCount.integerValue'
else
  echo "❌ No challenge found for today"
  echo "Creating challenge manually..."

  # Generate a simple level structure (you can enhance this)
  curl -s -X PATCH "${BASE_URL}/dailyChallenges/${TODAY}?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
      "fields": {
        "id": {"stringValue": "'"${TODAY}"'"},
        "completionCount": {"integerValue": "0"},
        "notificationSent": {"booleanValue": false},
        "createdAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
        "level": {
          "mapValue": {
            "fields": {
              "id": {"stringValue": "daily-'"${TODAY}"'"},
              "gridSize": {"integerValue": "6"},
              "difficulty": {"stringValue": "medium"}
            }
          }
        }
      }
    }' | jq '.'
  echo "✅ Challenge created!"
fi

echo ""
echo "2️⃣ Checking leaderboard..."
LEADERBOARD=$(curl -s "${BASE_URL}/leaderboard?key=${API_KEY}&pageSize=5")
ENTRY_COUNT=$(echo "$LEADERBOARD" | jq -r '.documents | length')
echo "Found $ENTRY_COUNT leaderboard entries"

echo ""
echo "✅ Production test complete!"
echo ""
echo "🌐 View in Firebase Console:"
echo "   https://console.firebase.google.com/project/hexbuzz-game/firestore"
