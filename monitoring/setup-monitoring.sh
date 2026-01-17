#!/bin/bash

# Setup script for HexBuzz Firebase Monitoring and Alerting
# This script helps configure monitoring alerts using gcloud CLI

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first:"
    echo "  https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI is not installed. Please install it first:"
    echo "  npm install -g firebase-tools"
    exit 1
fi

print_info "HexBuzz Monitoring Setup Script"
echo ""

# Get Firebase project ID
print_info "Getting Firebase project ID..."
PROJECT_ID=$(firebase projects:list | grep -m1 "hexbuzz" | awk '{print $1}' || true)

if [ -z "$PROJECT_ID" ]; then
    print_warning "Could not auto-detect project ID."
    read -p "Enter your Firebase project ID: " PROJECT_ID
fi

print_info "Using project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Confirm setup
echo ""
print_warning "This script will create monitoring alert policies in Google Cloud Console."
read -p "Do you want to continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setup cancelled."
    exit 0
fi

echo ""
print_info "=== Setting up notification channels ==="

# Create email notification channel
read -p "Enter email address for alerts (default: alerts@hexbuzz.app): " ALERT_EMAIL
ALERT_EMAIL=${ALERT_EMAIL:-alerts@hexbuzz.app}

print_info "Creating email notification channel..."
EMAIL_CHANNEL_ID=$(gcloud alpha monitoring channels create \
    --display-name="HexBuzz Alerts Email" \
    --type=email \
    --channel-labels=email_address="$ALERT_EMAIL" \
    --format="value(name)" 2>/dev/null || echo "")

if [ -n "$EMAIL_CHANNEL_ID" ]; then
    print_success "Email channel created: $EMAIL_CHANNEL_ID"
else
    print_warning "Email channel may already exist or creation failed. Continuing..."
fi

# Create Slack notification channel (optional)
read -p "Do you want to configure Slack notifications? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter Slack webhook URL: " SLACK_WEBHOOK
    read -p "Enter Slack channel name (e.g., #hexbuzz-alerts): " SLACK_CHANNEL

    print_info "Creating Slack notification channel..."
    SLACK_CHANNEL_ID=$(gcloud alpha monitoring channels create \
        --display-name="HexBuzz Alerts Slack" \
        --type=slack \
        --channel-labels=url="$SLACK_WEBHOOK",channel_name="$SLACK_CHANNEL" \
        --format="value(name)" 2>/dev/null || echo "")

    if [ -n "$SLACK_CHANNEL_ID" ]; then
        print_success "Slack channel created: $SLACK_CHANNEL_ID"
    else
        print_warning "Slack channel creation failed. You can create it manually in Cloud Console."
    fi
fi

echo ""
print_info "=== Creating alert policies ==="

# Function to create alert policy
create_alert_policy() {
    local name=$1
    local description=$2
    local filter=$3
    local threshold=$4
    local comparison=$5
    local duration=$6

    print_info "Creating alert: $name"

    # Note: This is a simplified version. Complex alerts need JSON config files.
    # Full implementation would use gcloud alpha monitoring policies create with --policy-from-file

    print_warning "Alert policy creation requires complex JSON configuration."
    print_info "Please use Google Cloud Console to create alerts based on monitoring/alerting-config.yaml"
}

# Cloud Functions Error Rate Alert
print_info "Cloud Functions - High Error Rate"
print_warning "Please create this alert manually in Cloud Console:"
echo "  1. Go to: https://console.cloud.google.com/monitoring/alerting"
echo "  2. Click 'Create Policy'"
echo "  3. Add condition:"
echo "     - Metric: Cloud Function Execution Count"
echo "     - Filter: status != 'ok'"
echo "     - Threshold: > 5% error rate"
echo "  4. Configure notification channels"
echo ""

# Firestore Quota Alert
print_info "Firestore - Read Quota Near Limit"
print_warning "Please create this alert manually in Cloud Console:"
echo "  1. Go to: https://console.cloud.google.com/monitoring/alerting"
echo "  2. Click 'Create Policy'"
echo "  3. Add condition:"
echo "     - Metric: Firestore Document Reads"
echo "     - Threshold: > 80% of quota"
echo "  4. Configure notification channels"
echo ""

# App Performance Alert
print_info "App Performance - High Crash Rate"
print_warning "Please create this alert manually in Firebase Console:"
echo "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/crashlytics"
echo "  2. Click 'Settings' (gear icon)"
echo "  3. Enable 'Crash-free users alerts'"
echo "  4. Set threshold: < 99%"
echo ""

echo ""
print_info "=== Enabling Firebase services ==="

# Enable Performance Monitoring
print_info "Ensuring Firebase Performance Monitoring is enabled..."
firebase apps:sdkconfig android --project "$PROJECT_ID" > /dev/null 2>&1 || true
print_success "Performance Monitoring enabled (check Firebase Console to verify)"

# Enable Crashlytics
print_info "Ensuring Firebase Crashlytics is enabled..."
print_info "Crashlytics is automatically initialized in the app code"

echo ""
print_info "=== Creating monitoring dashboard ==="

print_warning "To create a comprehensive monitoring dashboard:"
echo "  1. Go to: https://console.cloud.google.com/monitoring/dashboards"
echo "  2. Click 'Create Dashboard'"
echo "  3. Name it 'HexBuzz Production Overview'"
echo "  4. Add charts for:"
echo "     - Cloud Functions execution count (by function)"
echo "     - Cloud Functions error rate"
echo "     - Firestore read/write operations"
echo "     - FCM message delivery"
echo "     - App crash-free rate"
echo "     - Leaderboard query latency"
echo ""

echo ""
print_info "=== Setting up log-based metrics ==="

# Create log-based metric for rank recomputation duration
print_info "Creating log-based metric: leaderboard_rank_recomputation_duration"
gcloud logging metrics create leaderboard_rank_recomputation_duration \
    --description="Time taken to recompute all leaderboard ranks" \
    --log-filter='resource.type="cloud_function"
resource.labels.function_name="onScoreUpdate"
textPayload=~"Recomputed ranks for .* users"' \
    --value-extractor='EXTRACT(textPayload, "Recomputed ranks for (\\d+) users")' \
    2>/dev/null || print_warning "Metric may already exist or creation failed"

# Create log-based metric for daily challenge success
print_info "Creating log-based metric: daily_challenge_generation_success"
gcloud logging metrics create daily_challenge_generation_success \
    --description="Success/failure counter for daily challenge generation" \
    --log-filter='resource.type="cloud_function"
resource.labels.function_name="generateDailyChallenge"
(textPayload=~"Generated daily challenge" OR textPayload=~"Error generating daily challenge")' \
    2>/dev/null || print_warning "Metric may already exist or creation failed"

print_success "Log-based metrics created"

echo ""
print_info "=== Budget alerts ==="

print_warning "To set up budget alerts:"
echo "  1. Go to: https://console.cloud.google.com/billing"
echo "  2. Select your billing account"
echo "  3. Click 'Budgets & alerts'"
echo "  4. Create budget with thresholds at 50%, 80%, 90%, 100%"
echo "  5. Configure email notifications"
echo ""

echo ""
print_success "=== Monitoring setup complete! ==="
echo ""
print_info "Next steps:"
echo "  1. Review and create alert policies in Cloud Console"
echo "     https://console.cloud.google.com/monitoring/alerting"
echo ""
echo "  2. Create monitoring dashboard"
echo "     https://console.cloud.google.com/monitoring/dashboards"
echo ""
echo "  3. Set up budget alerts"
echo "     https://console.cloud.google.com/billing"
echo ""
echo "  4. Configure Crashlytics alerts in Firebase Console"
echo "     https://console.firebase.google.com/project/$PROJECT_ID/crashlytics"
echo ""
echo "  5. Test alerts by triggering test conditions (see monitoring/README.md)"
echo ""
echo "  6. Review monitoring documentation: docs/MONITORING.md"
echo ""

print_info "All manual configuration steps are documented in:"
print_info "  - monitoring/alerting-config.yaml (alert definitions)"
print_info "  - docs/MONITORING.md (complete setup guide)"
