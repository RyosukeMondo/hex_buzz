#!/bin/bash
# Simple Firestore population using REST API

set -e

PROJECT_ID="hexbuzz-game"
API_KEY="AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

TODAY=$(date -u +%Y-%m-%d)

echo "🔥 Populating Firestore"
echo "📅 Date: ${TODAY}"
echo ""

# Create daily challenge with simplified structure
echo "📝 Creating daily challenge..."

curl -s -X PATCH "${BASE_URL}/dailyChallenges/${TODAY}?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "id": {"stringValue": "'"${TODAY}"'"},
      "createdAt": {"timestampValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
      "completionCount": {"integerValue": "0"},
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
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "3"}, "isObstacle": {"booleanValue": false}}}},
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
  }' | jq -r 'if .error then "❌ Error: " + .error.message else "✓ Success" end'

# Create leaderboard entries
echo ""
echo "📊 Creating leaderboard..."

declare -a USERS=("BeeKeeper:245" "HoneyHunter:198" "BuzzMaster:187" "HiveQueen:165" "PollenCollector:142")

for i in "${!USERS[@]}"; do
    IFS=':' read -r USERNAME STARS <<< "${USERS[$i]}"
    USER_ID="test_user_$((i+1))"

    RESULT=$(curl -s -X PATCH "${BASE_URL}/leaderboard/${USER_ID}?key=${API_KEY}" \
      -H "Content-Type: application/json" \
      -d '{
        "fields": {
          "userId": {"stringValue": "'"${USER_ID}"'"},
          "username": {"stringValue": "'"${USERNAME}"'"},
          "totalStars": {"integerValue": "'"${STARS}"'"},
          "updatedAt": {"timestampValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
          "lastLevel": {"stringValue": "level-1"}
        }
      }')

    if echo "$RESULT" | grep -q "error"; then
        echo "  ❌ ${USERNAME}: $(echo "$RESULT" | jq -r '.error.message')"
    else
        echo "  ✓ ${USERNAME} (${STARS} stars)"
    fi
done

echo ""
echo "✅ Done!"
echo "🚀 Test: https://mondo-ai-studio.xvps.jp/hex_buzz/"
