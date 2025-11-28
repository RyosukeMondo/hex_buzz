#!/bin/bash
# Build and deploy HexBuzz to Google Play Store
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"

# Default track
TRACK="${1:-internal}"

echo "🔨 Building release AAB..."
cd "$PROJECT_DIR"

# Clean and build
flutter clean
flutter pub get
flutter build appbundle --release

if [[ ! -f "$AAB_PATH" ]]; then
    echo "❌ Build failed: AAB not found at $AAB_PATH"
    exit 1
fi

echo "✅ Build complete: $AAB_PATH"
echo ""

# Check for key file
if [[ -z "$GOOGLE_PLAY_KEY_FILE" ]]; then
    echo "⚠️  GOOGLE_PLAY_KEY_FILE not set"
    echo ""
    echo "To deploy, you need to:"
    echo "1. Create a service account at: https://console.cloud.google.com/iam-admin/serviceaccounts"
    echo "2. Enable Google Play Android Developer API"
    echo "3. Download JSON key and set: export GOOGLE_PLAY_KEY_FILE=/path/to/key.json"
    echo "4. In Play Console > Settings > API access, link and grant 'Release manager' access"
    echo ""
    echo "Then run: $0 $TRACK"
    exit 0
fi

echo "🚀 Deploying to $TRACK track..."
"$SCRIPT_DIR/deploy_play_store.py" --aab "$AAB_PATH" --track "$TRACK"

echo ""
echo "🎉 Done! Check Play Console for status."
