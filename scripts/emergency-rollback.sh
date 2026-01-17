#!/bin/bash
# emergency-rollback.sh
# Emergency rollback script for HexBuzz production deployment

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
FIREBASE_PROJECT="${FIREBASE_PROJECT:-production}"

echo -e "${RED}⚠️  EMERGENCY ROLLBACK${NC}"
echo "=================================="
echo "This script will rollback the production deployment."
echo "Project: $FIREBASE_PROJECT"
echo "Timestamp: $(date)"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback? Type 'ROLLBACK' to confirm: " confirm
if [ "$confirm" != "ROLLBACK" ]; then
    echo "Rollback cancelled."
    exit 1
fi

echo ""
echo "Starting emergency rollback..."

# Step 1: Rollback Firebase Hosting
echo ""
echo "Step 1: Rolling back Firebase Hosting..."
if firebase hosting:rollback --project "$FIREBASE_PROJECT" --force; then
    echo -e "${GREEN}✓${NC} Hosting rolled back successfully"
else
    echo -e "${RED}✗${NC} Hosting rollback failed (may be at oldest version)"
fi

# Step 2: Rollback Firestore Rules
echo ""
echo "Step 2: Rolling back Firestore Rules..."
read -p "Rollback Firestore rules to previous commit? (yes/no): " rollback_rules

if [ "$rollback_rules" = "yes" ]; then
    # Save current rules
    cp firestore.rules firestore.rules.backup.$(date +%Y%m%d_%H%M%S)

    # Checkout previous version
    git checkout HEAD~1 firestore.rules

    # Deploy previous rules
    if firebase deploy --only firestore:rules --project "$FIREBASE_PROJECT"; then
        echo -e "${GREEN}✓${NC} Firestore rules rolled back successfully"

        # Ask if we should keep the rollback
        read -p "Keep rolled back rules? (yes/no): " keep_rules
        if [ "$keep_rules" != "yes" ]; then
            git checkout HEAD firestore.rules
            echo "Firestore rules reverted to current version"
        fi
    else
        echo -e "${RED}✗${NC} Firestore rules rollback failed"
        git checkout HEAD firestore.rules
    fi
else
    echo "Skipping Firestore rules rollback"
fi

# Step 3: Cloud Functions rollback
echo ""
echo "Step 3: Cloud Functions rollback"
echo -e "${YELLOW}⚠${NC} Cloud Functions must be rolled back manually"
echo ""
echo "To rollback a specific function:"
echo "  1. Identify the problematic function"
echo "  2. Delete it: firebase functions:delete FUNCTION_NAME --project $FIREBASE_PROJECT"
echo "  3. Checkout previous version: git checkout HEAD~1 functions/"
echo "  4. Rebuild: cd functions && npm run build && cd .."
echo "  5. Redeploy: firebase deploy --only functions:FUNCTION_NAME --project $FIREBASE_PROJECT"
echo ""
echo "Or rollback entire functions directory:"
echo "  git checkout HEAD~1 functions/"
echo "  cd functions && npm install && npm run build && cd .."
echo "  firebase deploy --only functions --project $FIREBASE_PROJECT"
echo ""

read -p "Attempt Cloud Functions rollback now? (yes/no): " rollback_functions

if [ "$rollback_functions" = "yes" ]; then
    # Save current functions
    cp -r functions functions.backup.$(date +%Y%m%d_%H%M%S)

    # Checkout previous version
    git checkout HEAD~1 functions/

    # Build and deploy
    echo "Building previous version of Cloud Functions..."
    cd functions
    if npm install && npm run build; then
        cd ..
        echo "Deploying previous version of Cloud Functions..."
        if firebase deploy --only functions --project "$FIREBASE_PROJECT"; then
            echo -e "${GREEN}✓${NC} Cloud Functions rolled back successfully"

            read -p "Keep rolled back functions? (yes/no): " keep_functions
            if [ "$keep_functions" != "yes" ]; then
                git checkout HEAD functions/
                echo "Functions reverted to current version"
            fi
        else
            echo -e "${RED}✗${NC} Cloud Functions rollback failed"
            cd ..
            git checkout HEAD functions/
        fi
    else
        echo -e "${RED}✗${NC} Cloud Functions build failed"
        cd ..
        git checkout HEAD functions/
    fi
else
    echo "Skipping Cloud Functions rollback"
fi

# Step 4: Verify rollback
echo ""
echo "Step 4: Verifying rollback..."
echo "Running validation script..."
if [ -f "./scripts/validate-production.sh" ]; then
    ./scripts/validate-production.sh
else
    echo -e "${YELLOW}⚠${NC} Validation script not found"
fi

# Summary
echo ""
echo "=================================="
echo "Emergency Rollback Summary"
echo "=================================="
echo ""
echo "✓ Hosting: Rolled back to previous release"
echo "? Firestore Rules: $([ "$rollback_rules" = "yes" ] && echo "Rolled back" || echo "Not rolled back")"
echo "? Cloud Functions: $([ "$rollback_functions" = "yes" ] && echo "Rolled back" || echo "Not rolled back")"
echo ""
echo "Next steps:"
echo "1. Monitor Firebase Console for error rates"
echo "2. Check function logs: firebase functions:log --project $FIREBASE_PROJECT --follow"
echo "3. Verify production URL: https://hex-buzz.web.app"
echo "4. Investigate root cause of the issue"
echo "5. Plan a proper fix and redeployment"
echo "6. Document incident in incident log"
echo ""
echo -e "${YELLOW}⚠${NC} Remember to commit any kept rollback changes!"
echo ""
