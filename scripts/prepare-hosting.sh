#!/bin/bash
# Prepare Firebase Hosting deployment
# This script copies legal documents to the web build directory

set -e

echo "Preparing Firebase Hosting deployment..."

# Ensure build/web directory exists
if [ ! -d "build/web" ]; then
    echo "Error: build/web directory not found. Run 'flutter build web' first."
    exit 1
fi

# Copy legal documents to build/web
echo "Copying legal documents..."
cp public/privacy-policy.html build/web/
cp public/terms-of-service.html build/web/

echo "Legal documents copied successfully."
echo ""
echo "Files ready for deployment:"
echo "  - build/web/privacy-policy.html"
echo "  - build/web/terms-of-service.html"
echo ""
echo "URLs after deployment:"
echo "  - https://YOUR-PROJECT.web.app/privacy-policy.html"
echo "  - https://YOUR-PROJECT.web.app/terms-of-service.html"
echo ""
echo "Ready to deploy with: firebase deploy --only hosting"
