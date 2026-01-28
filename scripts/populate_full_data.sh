#!/bin/bash
# Comprehensive Firestore population with all needed data

set -e

PROJECT_ID="hexbuzz-game"
API_KEY="AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

TODAY=$(date -u +%Y-%m-%d)

echo "🔥 Comprehensive Firestore Population"
echo "📅 Date: ${TODAY}"
echo ""

# Create daily challenge with completions subcollection
echo "📝 Creating daily challenge with completions..."

# Create the main challenge
curl -s -X PATCH "${BASE_URL}/dailyChallenges/${TODAY}?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "id": {"stringValue": "'"${TODAY}"'"},
      "createdAt": {"timestampValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
      "completionCount": {"integerValue": "3"},
      "notificationSent": {"booleanValue": false},
      "level": {
        "mapValue": {
          "fields": {
            "id": {"stringValue": "daily-'"${TODAY}"'"},
            "gridSize": {"integerValue": "6"},
            "difficulty": {"stringValue": "medium"},
            "startPosition": {
              "mapValue": {
                "fields": {
                  "q": {"integerValue": "0"},
                  "r": {"integerValue": "5"},
                  "isObstacle": {"booleanValue": false}
                }
              }
            },
            "endPosition": {
              "mapValue": {
                "fields": {
                  "q": {"integerValue": "5"},
                  "r": {"integerValue": "5"},
                  "isObstacle": {"booleanValue": false}
                }
              }
            },
            "cells": {
              "arrayValue": {
                "values": [
                  {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": true}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "4"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "5"}, "isObstacle": {"booleanValue": false}}}}
                ]
              }
            }
          }
        }
      }
    }
  }' > /dev/null

echo "  ✓ Daily challenge created"

# Create completions for the daily challenge
echo "  Creating challenge completions..."

for i in {1..3}; do
    USER_ID="test_user_${i}"
    STARS=$((4 - i))
    TIME=$((30000 + i * 5000))

    curl -s -X PATCH "${BASE_URL}/dailyChallenges/${TODAY}/completions/${USER_ID}?key=${API_KEY}" \
      -H "Content-Type: application/json" \
      -d '{
        "fields": {
          "userId": {"stringValue": "'"${USER_ID}"'"},
          "stars": {"integerValue": "'"${STARS}"'"},
          "completionTimeMs": {"integerValue": "'"${TIME}"'"},
          "completedAt": {"timestampValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}
        }
      }' > /dev/null

    echo "    ✓ Completion for ${USER_ID} (${STARS} stars, ${TIME}ms)"
done

# Create comprehensive leaderboard
echo ""
echo "📊 Creating comprehensive leaderboard..."

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

for i in "${!USERS[@]}"; do
    IFS=':' read -r USERNAME STARS <<< "${USERS[$i]}"
    USER_ID="test_user_$((i+1))"

    curl -s -X PATCH "${BASE_URL}/leaderboard/${USER_ID}?key=${API_KEY}" \
      -H "Content-Type: application/json" \
      -d '{
        "fields": {
          "userId": {"stringValue": "'"${USER_ID}"'"},
          "username": {"stringValue": "'"${USERNAME}"'"},
          "totalStars": {"integerValue": "'"${STARS}"'"},
          "updatedAt": {"timestampValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
          "lastLevel": {"stringValue": "level-'"$((i+1))"'"},
          "avatarUrl": {"nullValue": null}
        }
      }' > /dev/null

    echo "  ✓ ${USERNAME} (${STARS} stars)"
done

echo ""
echo "✅ Comprehensive data populated!"
echo "   - Daily challenge: ${TODAY}"
echo "   - Challenge completions: 3"
echo "   - Leaderboard: 10 users"
echo ""
echo "🚀 Test: https://mondo-ai-studio.xvps.jp/hex_buzz/"
echo "   Clear browser cache (Ctrl+Shift+R) and test!"
