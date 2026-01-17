#!/bin/bash

# Firebase Deployment Script
# Usage: ./scripts/deploy-firebase.sh [staging|production] [--functions-only|--hosting-only|--all]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="staging"
DEPLOY_TARGET="all"

# Parse arguments
if [ $# -ge 1 ]; then
    ENVIRONMENT=$1
fi

if [ $# -ge 2 ]; then
    case $2 in
        --functions-only)
            DEPLOY_TARGET="functions"
            ;;
        --hosting-only)
            DEPLOY_TARGET="hosting"
            ;;
        --all)
            DEPLOY_TARGET="all"
            ;;
        *)
            echo -e "${RED}Invalid deploy target: $2${NC}"
            echo "Usage: ./scripts/deploy-firebase.sh [staging|production] [--functions-only|--hosting-only|--all]"
            exit 1
            ;;
    esac
fi

echo -e "${GREEN}HexBuzz Firebase Deployment Script${NC}"
echo "Environment: $ENVIRONMENT"
echo "Deploy target: $DEPLOY_TARGET"
echo ""

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo -e "${RED}Error: Environment must be 'staging' or 'production'${NC}"
    exit 1
fi

# Confirm production deployment
if [ "$ENVIRONMENT" == "production" ]; then
    echo -e "${YELLOW}WARNING: You are about to deploy to PRODUCTION${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}Error: Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Set Firebase project
echo -e "${GREEN}Setting Firebase project to: $ENVIRONMENT${NC}"
firebase use $ENVIRONMENT

# Pre-deployment checks
echo -e "${GREEN}Running pre-deployment checks...${NC}"

# Check if functions directory exists
if [ ! -d "functions" ]; then
    echo -e "${RED}Error: functions directory not found${NC}"
    exit 1
fi

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}Error: firebase.json not found${NC}"
    exit 1
fi

# Build and lint functions
if [ "$DEPLOY_TARGET" == "functions" ] || [ "$DEPLOY_TARGET" == "all" ]; then
    echo -e "${GREEN}Building Cloud Functions...${NC}"
    cd functions

    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi

    # Lint
    echo "Linting..."
    npm run lint

    # Build
    echo "Building..."
    npm run build

    cd ..
    echo -e "${GREEN}✓ Cloud Functions built successfully${NC}"
fi

# Build web app for hosting
if [ "$DEPLOY_TARGET" == "hosting" ] || [ "$DEPLOY_TARGET" == "all" ]; then
    echo -e "${GREEN}Building Flutter web app...${NC}"

    # Check if Flutter is available
    if ! command -v flutter &> /dev/null; then
        echo -e "${YELLOW}Warning: Flutter not found, skipping web build${NC}"
        echo "Web hosting will deploy existing build/web content"
    else
        flutter pub get
        flutter build web --release --web-renderer canvaskit

        # Prepare hosting content (copy legal docs)
        if [ -f "scripts/prepare-hosting.sh" ]; then
            bash scripts/prepare-hosting.sh
        fi

        echo -e "${GREEN}✓ Web app built successfully${NC}"
    fi
fi

# Determine what to deploy
DEPLOY_ONLY=""
if [ "$DEPLOY_TARGET" == "functions" ]; then
    DEPLOY_ONLY="--only functions"
elif [ "$DEPLOY_TARGET" == "hosting" ]; then
    DEPLOY_ONLY="--only hosting"
else
    DEPLOY_ONLY="--only functions,firestore,hosting"
fi

# Deploy to Firebase
echo -e "${GREEN}Deploying to Firebase ($ENVIRONMENT)...${NC}"
echo "Deploy command: firebase deploy $DEPLOY_ONLY"
echo ""

firebase deploy $DEPLOY_ONLY

# Success message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$ENVIRONMENT" == "production" ]; then
    echo "Production URLs:"
    echo "  Web: https://hex-buzz.web.app"
    echo "  Functions: Check Firebase Console"
else
    echo "Staging deployment complete"
    echo "Check Firebase Console for URLs"
fi

echo ""
echo "Next steps:"
echo "  1. Check Firebase Console for deployment status"
echo "  2. Test deployed functions"
echo "  3. Verify Firestore rules and indexes"
if [ "$DEPLOY_TARGET" == "hosting" ] || [ "$DEPLOY_TARGET" == "all" ]; then
    echo "  4. Test web app at hosting URL"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
