#!/bin/bash
# validate-production.sh
# Post-deployment validation script for HexBuzz production environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PRODUCTION_URL="${PRODUCTION_URL:-https://hex-buzz.web.app}"
FIREBASE_PROJECT="${FIREBASE_PROJECT:-production}"
API_TIMEOUT=10

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Functions
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

print_failure() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_failure "$1 is not installed"
        return 1
    fi
}

check_url() {
    local url=$1
    local name=$2

    if curl -s -o /dev/null -w "%{http_code}" --max-time "$API_TIMEOUT" "$url" | grep -q "200\|301\|302"; then
        print_success "$name is accessible"
        return 0
    else
        print_failure "$name is not accessible"
        return 1
    fi
}

check_url_contains() {
    local url=$1
    local name=$2
    local pattern=$3

    local response=$(curl -s --max-time "$API_TIMEOUT" "$url" 2>/dev/null)
    if echo "$response" | grep -q "$pattern"; then
        print_success "$name contains expected content"
        return 0
    else
        print_failure "$name does not contain expected content"
        return 1
    fi
}

# Start validation
clear
echo "🔍 HexBuzz Production Validation"
echo "=================================="
echo "Production URL: $PRODUCTION_URL"
echo "Firebase Project: $FIREBASE_PROJECT"
echo "Timestamp: $(date)"
echo ""

# Check prerequisites
print_header "1. Prerequisites Check"

check_command "curl"
check_command "firebase"
check_command "jq" || print_warning "jq not installed (optional for JSON parsing)"

# Check Firebase authentication
if firebase projects:list 2>&1 | grep -q "$FIREBASE_PROJECT"; then
    print_success "Firebase project '$FIREBASE_PROJECT' is accessible"
else
    print_failure "Firebase project '$FIREBASE_PROJECT' is not accessible"
fi

# Check web hosting
print_header "2. Web Hosting Check"

check_url "$PRODUCTION_URL" "Production web app"
check_url "$PRODUCTION_URL/privacy-policy.html" "Privacy policy page"
check_url "$PRODUCTION_URL/terms-of-service.html" "Terms of service page"

# Check web app content
if check_url_contains "$PRODUCTION_URL" "Main app page" "HexBuzz"; then
    :
fi

# Check if Flutter app loads
if check_url_contains "$PRODUCTION_URL" "Flutter app" "flutter"; then
    :
else
    print_warning "Flutter app may not be properly initialized"
fi

# Check Cloud Functions
print_header "3. Cloud Functions Check"

echo "Checking deployed functions..."
FUNCTIONS=$(firebase functions:list --project "$FIREBASE_PROJECT" 2>/dev/null || echo "")

if [ -z "$FUNCTIONS" ]; then
    print_failure "Unable to retrieve Cloud Functions list"
else
    print_success "Cloud Functions list retrieved"

    # Check for expected functions
    for func in "onScoreUpdate" "generateDailyChallenge" "sendDailyChallengeNotifications" "onUserCreated" "recomputeAllRanks"; do
        if echo "$FUNCTIONS" | grep -q "$func"; then
            print_success "Function '$func' is deployed"
        else
            print_failure "Function '$func' is NOT deployed"
        fi
    done
fi

# Check Firestore rules
print_header "4. Firestore Configuration Check"

echo "Checking Firestore rules..."
if firebase firestore:rules --project "$FIREBASE_PROJECT" &> /dev/null; then
    print_success "Firestore rules are deployed"
else
    print_failure "Firestore rules check failed"
fi

# Check Firestore indexes
echo "Checking Firestore indexes..."
INDEXES=$(firebase firestore:indexes --project "$FIREBASE_PROJECT" 2>/dev/null || echo "")

if [ -z "$INDEXES" ]; then
    print_warning "Unable to retrieve Firestore indexes"
else
    if echo "$INDEXES" | grep -q "READY\|CREATING"; then
        print_success "Firestore indexes are configured"

        # Check for CREATING status
        if echo "$INDEXES" | grep -q "CREATING"; then
            print_warning "Some indexes are still being created"
        fi
    else
        print_failure "Firestore indexes may not be properly configured"
    fi
fi

# Check recent function logs
print_header "5. Cloud Functions Logs Check"

echo "Checking recent function logs for errors..."
RECENT_LOGS=$(firebase functions:log --project "$FIREBASE_PROJECT" --limit 50 2>/dev/null || echo "")

if [ -z "$RECENT_LOGS" ]; then
    print_warning "Unable to retrieve function logs"
else
    ERROR_COUNT=$(echo "$RECENT_LOGS" | grep -c "ERROR\|Error\|error" || echo "0")

    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_success "No errors in recent function logs"
    elif [ "$ERROR_COUNT" -lt 5 ]; then
        print_warning "$ERROR_COUNT errors found in recent logs (acceptable threshold)"
    else
        print_failure "$ERROR_COUNT errors found in recent logs (investigate immediately)"
    fi
fi

# Check Firebase Console accessibility
print_header "6. Firebase Console Check"

echo "Verify the following in Firebase Console:"
echo "  - Authentication: Google provider enabled"
echo "  - Firestore: Database created and accessible"
echo "  - Functions: All functions deployed without errors"
echo "  - Hosting: Web app deployed and serving"
echo "  - Performance: Monitoring active"
echo "  - Crashlytics: Initialized (if applicable)"
echo ""
print_warning "Manual verification required in Firebase Console"

# Performance check
print_header "7. Performance Check"

echo "Measuring page load time..."
START_TIME=$(date +%s%N)
curl -s -o /dev/null "$PRODUCTION_URL" --max-time 30
END_TIME=$(date +%s%N)
LOAD_TIME=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$LOAD_TIME" -lt 3000 ]; then
    print_success "Page load time: ${LOAD_TIME}ms (excellent)"
elif [ "$LOAD_TIME" -lt 5000 ]; then
    print_warning "Page load time: ${LOAD_TIME}ms (acceptable)"
else
    print_failure "Page load time: ${LOAD_TIME}ms (too slow, investigate)"
fi

# SSL certificate check
print_header "8. SSL Certificate Check"

if curl -sI "$PRODUCTION_URL" | grep -q "HTTP/2 200\|HTTP/2 301\|HTTP/2 302"; then
    print_success "HTTPS is properly configured"
else
    print_failure "HTTPS configuration issue detected"
fi

# Print summary
print_header "Validation Summary"

echo ""
echo "Results:"
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ Validation PASSED${NC}"
    echo ""
    echo "Production deployment appears healthy."
    echo "Continue monitoring for the next 30 minutes."
    exit 0
else
    echo -e "${RED}✗ Validation FAILED${NC}"
    echo ""
    echo "Issues detected in production deployment."
    echo "Review failed checks above and investigate immediately."
    echo ""
    echo "Recommended actions:"
    echo "1. Check Firebase Console for detailed error messages"
    echo "2. Review Cloud Functions logs: firebase functions:log --project $FIREBASE_PROJECT"
    echo "3. Verify Firestore rules and indexes"
    echo "4. Check browser console for client-side errors"
    echo "5. Consider rolling back if critical issues found"
    exit 1
fi
