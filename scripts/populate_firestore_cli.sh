#!/bin/bash
# Populate Firestore using REST API (no auth issues!)

set -e

PROJECT_ID="hexbuzz-game"
API_KEY="AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

# Get today's date in UTC (YYYY-MM-DD)
TODAY=$(date -u +%Y-%m-%d)

echo "🔥 Populating Firestore for project: ${PROJECT_ID}"
echo "📅 Today's date (UTC): ${TODAY}"
echo ""

# Function to generate a simple hex level
generate_level() {
    cat <<EOF
{
  "fields": {
    "id": {"stringValue": "daily-${TODAY}"},
    "gridSize": {"integerValue": "6"},
    "difficulty": {"stringValue": "medium"},
    "cells": {
      "arrayValue": {
        "values": [
          {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": true}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": true}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "2"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": true}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "1"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "2"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": true}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "0"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "1"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "2"}, "isObstacle": {"booleanValue": true}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
          {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}}
        ]
      }
    },
    "startPosition": {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}},
    "endPosition": {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}}
  }
}
EOF
}

# Create daily challenge
echo "📝 Step 1: Creating daily challenge..."
CHALLENGE_DATA=$(generate_level)

curl -s -X PATCH \
  "${BASE_URL}/dailyChallenges/${TODAY}?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"fields\": {
      \"id\": {\"stringValue\": \"${TODAY}\"},
      \"createdAt\": {\"timestampValue\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"},
      \"level\": $(echo "$CHALLENGE_DATA" | jq -r '.fields'),
      \"completionCount\": {\"integerValue\": \"0\"},
      \"notificationSent\": {\"booleanValue\": false}
    }
  }" > /tmp/challenge_response.json

if grep -q "error" /tmp/challenge_response.json; then
    echo "   ❌ Error creating daily challenge:"
    cat /tmp/challenge_response.json | jq '.'
    exit 1
else
    echo "   ✓ Daily challenge created successfully"
fi

# Create leaderboard entries
echo ""
echo "📊 Step 2: Creating leaderboard entries..."

declare -a USERS=(
    "BeeKeeper:245"
    "HoneyHunter:198"
    "BuzzMaster:187"
    "HiveQueen:165"
    "PollenCollector:142"
    "NectarSeeker:128"
    "WaxWorker:115"
    "DroneRanger:98"
    "HoneyDipper:87"
    "BumbleBuddy:76"
)

COUNT=1
for USER_DATA in "${USERS[@]}"; do
    USERNAME=$(echo $USER_DATA | cut -d: -f1)
    STARS=$(echo $USER_DATA | cut -d: -f2)
    USER_ID="test_user_${COUNT}"

    curl -s -X PATCH \
      "${BASE_URL}/leaderboard/${USER_ID}?key=${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"fields\": {
          \"userId\": {\"stringValue\": \"${USER_ID}\"},
          \"username\": {\"stringValue\": \"${USERNAME}\"},
          \"avatarUrl\": {\"nullValue\": null},
          \"totalStars\": {\"integerValue\": \"${STARS}\"},
          \"updatedAt\": {\"timestampValue\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"},
          \"lastLevel\": {\"stringValue\": \"level-1\"}
        }
      }" > /tmp/leaderboard_response_${COUNT}.json

    if grep -q "error" /tmp/leaderboard_response_${COUNT}.json; then
        echo "   ❌ Error creating ${USERNAME}:"
        cat /tmp/leaderboard_response_${COUNT}.json | jq '.'
    else
        echo "   ✓ Created ${USERNAME} (${STARS} stars)"
    fi

    COUNT=$((COUNT + 1))
done

echo ""
echo "✅ Done! Firestore populated successfully."
echo "   - Daily challenge: ${TODAY}"
echo "   - Leaderboard: 10 users"
echo ""
echo "🚀 Test the app at: https://mondo-ai-studio.xvps.jp/hex_buzz/"
