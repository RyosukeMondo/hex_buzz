#!/bin/bash
# Create a proper daily challenge matching the Flutter app's Level model

API_KEY="AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc"
PROJECT_ID="hexbuzz-game"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"
TODAY=$(date -u +%Y-%m-%d)

echo "🐝 Creating properly formatted daily challenge for $TODAY..."
echo ""

# Generate a simple 6x6 hex grid with checkpoints
# Cells for a 6x6 hex grid with checkpoint 1 at (0,3) and checkpoint 2 at (5,3)
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
            "size": {"integerValue": "6"},
            "checkpointCount": {"integerValue": "2"},
            "cells": {
              "arrayValue": {
                "values": [
                  {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "3"}, "checkpoint": {"integerValue": "1"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "4"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "0"}, "r": {"integerValue": "5"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "2"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "3"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "4"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "1"}, "r": {"integerValue": "5"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "1"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "2"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "3"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "4"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "2"}, "r": {"integerValue": "5"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "0"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "1"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "2"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "3"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "4"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "3"}, "r": {"integerValue": "5"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "0"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "1"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "2"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "4"}, "r": {"integerValue": "3"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "0"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "1"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "2"}, "visited": {"booleanValue": false}}}},
                  {"mapValue": {"fields": {"q": {"integerValue": "5"}, "r": {"integerValue": "3"}, "checkpoint": {"integerValue": "2"}, "visited": {"booleanValue": false}}}}
                ]
              }
            },
            "walls": {
              "arrayValue": {
                "values": [
                  {"mapValue": {"fields": {"q1": {"integerValue": "1"}, "r1": {"integerValue": "3"}, "q2": {"integerValue": "2"}, "r2": {"integerValue": "3"}}}},
                  {"mapValue": {"fields": {"q1": {"integerValue": "2"}, "r1": {"integerValue": "2"}, "q2": {"integerValue": "3"}, "r2": {"integerValue": "2"}}}},
                  {"mapValue": {"fields": {"q1": {"integerValue": "3"}, "r1": {"integerValue": "3"}, "q2": {"integerValue": "4"}, "r2": {"integerValue": "3"}}}}
                ]
              }
            }
          }
        }
      }
    }
  }' | jq '.'

echo ""
echo "✅ Daily challenge created!"
echo "🌐 View at: https://mondo-ai-studio.xvps.jp/hex_buzz#/daily-challenge"
