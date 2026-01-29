#!/bin/bash
# Test API Diagnostics Endpoint
# Zero UAT - fully automated REST API testing

echo "🔍 HexBuzz API Diagnostics - REST API Test"
echo "=========================================="
echo ""

# Try local emulator first, then production
if curl -s http://127.0.0.1:5001/hexbuzz-game/us-central1/apiDiagnostics > /dev/null 2>&1; then
    ENDPOINT="http://127.0.0.1:5001/hexbuzz-game/us-central1/apiDiagnostics"
    echo "📍 Using LOCAL emulator endpoint"
else
    ENDPOINT="https://us-central1-hexbuzz-game.cloudfunctions.net/apiDiagnostics"
    echo "📍 Using PRODUCTION endpoint"
fi

echo "🌐 Endpoint: $ENDPOINT"
echo ""

# Make request
echo "⏳ Running diagnostics..."
RESPONSE=$(curl -s -w "\n%{http_code}" "$ENDPOINT")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo "📊 Response:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP Status: $HTTP_CODE OK"
    echo ""

    # Pretty print JSON
    if command -v jq &> /dev/null; then
        echo "$BODY" | jq '.'
        echo ""
        echo "📋 Summary:"
        echo "$BODY" | jq -r '"Total Tests: \(.summary.totalTests)\nPassed: \(.summary.passed)\nFailed: \(.summary.failed)\nWarnings: \(.summary.warnings)"'
        echo ""
        echo "💡 Recommendations:"
        echo "$BODY" | jq -r '.recommendations[]'
    else
        echo "$BODY"
    fi
else
    echo "❌ HTTP Status: $HTTP_CODE"
    echo ""
    echo "$BODY"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Save to file
OUTPUT_FILE="api-diagnostics-$(date +%Y%m%d-%H%M%S).json"
echo "$BODY" > "$OUTPUT_FILE"
echo "💾 Full response saved to: $OUTPUT_FILE"
