#!/bin/bash
# Final Integration Testing Automation Script
# Runs comprehensive tests before production deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test result tracking
declare -a FAILED_TEST_NAMES=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_info "Running: $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        log_success "$test_name passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "$test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

# Function to skip a test
skip_test() {
    local test_name="$1"
    local reason="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))

    log_warning "Skipping: $test_name - $reason"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"

    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Please install Flutter."
        exit 1
    fi
    log_success "Flutter found: $(flutter --version | head -n 1)"

    # Check Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_warning "Firebase CLI not found. Some tests will be skipped."
    else
        log_success "Firebase CLI found"
    fi

    # Check if in correct directory
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Not in Flutter project root. Please run from project directory."
        exit 1
    fi

    log_success "All prerequisites met"
}

# Run unit tests
run_unit_tests() {
    log_section "Running Unit Tests"

    run_test "Dart unit tests" "flutter test --no-pub --coverage"

    if [ -f "coverage/lcov.info" ]; then
        log_info "Generating coverage report..."
        if command -v lcov &> /dev/null; then
            lcov --summary coverage/lcov.info 2>&1 | grep -E "lines\.*:" || true
        fi
    fi
}

# Run widget tests
run_widget_tests() {
    log_section "Running Widget Tests"

    run_test "Widget tests" "flutter test test/presentation/widgets/ --no-pub"
    run_test "Screen tests" "flutter test test/presentation/screens/ --no-pub"
}

# Run integration tests
run_integration_tests() {
    log_section "Running Integration Tests"

    # Check if integration test directory exists
    if [ -d "integration_test" ]; then
        run_test "Social/Competitive features E2E" "flutter test integration_test/social_competitive_features_test.dart"
    else
        skip_test "Integration tests" "Directory not found"
    fi
}

# Run security tests
run_security_tests() {
    log_section "Running Security Tests"

    run_test "Firestore security rules" "flutter test test/security/firestore_security_rules_test.dart --no-pub"
    run_test "Auth token validation" "flutter test test/security/auth_token_validation_test.dart --no-pub"
    run_test "Sensitive data exposure" "flutter test test/security/sensitive_data_exposure_test.dart --no-pub"
    run_test "Rate limiting" "flutter test test/security/rate_limiting_test.dart --no-pub"

    # Run Firestore emulator security tests if available
    if [ -f "test/security/firestore_security_emulator_test.sh" ]; then
        if command -v firebase &> /dev/null; then
            run_test "Firestore emulator security tests" "cd test/security && ./firestore_security_emulator_test.sh"
        else
            skip_test "Firestore emulator security tests" "Firebase CLI not installed"
        fi
    fi
}

# Run load tests
run_load_tests() {
    log_section "Running Load Tests"

    if [ -d "test/load" ] && [ -f "test/load/package.json" ]; then
        log_info "Installing load test dependencies..."
        cd test/load
        if command -v npm &> /dev/null; then
            npm install --silent > /dev/null 2>&1 || true

            # Run quick load tests (reduced user count for faster testing)
            run_test "Score submission load test" "node src/test-score-submission.js --users 50 --duration 30 --emulator"
            run_test "Leaderboard load test" "node src/test-leaderboard.js --users 50 --duration 30 --emulator"
            run_test "Daily challenge load test" "node src/test-daily-challenge.js --users 50 --duration 30 --emulator"

            cd ../..
        else
            skip_test "Load tests" "Node.js not installed"
        fi
    else
        skip_test "Load tests" "Load test directory not found"
    fi
}

# Run platform-specific builds
test_platform_builds() {
    log_section "Testing Platform Builds"

    # Android
    log_info "Testing Android build..."
    if flutter build apk --debug --quiet > /dev/null 2>&1; then
        log_success "Android APK builds successfully"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "Android APK build failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("Android APK build")
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # iOS (only on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Testing iOS build..."
        if flutter build ios --debug --no-codesign --quiet > /dev/null 2>&1; then
            log_success "iOS builds successfully"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "iOS build failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES+=("iOS build")
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        skip_test "iOS build" "Not running on macOS"
    fi

    # Web
    log_info "Testing Web build..."
    if flutter build web --quiet > /dev/null 2>&1; then
        log_success "Web builds successfully"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "Web build failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("Web build")
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Windows (only on Windows or Linux with Windows support)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        log_info "Testing Windows build..."
        if flutter build windows --quiet > /dev/null 2>&1; then
            log_success "Windows builds successfully"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "Windows build failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES+=("Windows build")
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        skip_test "Windows build" "Not running on Windows"
    fi
}

# Run static analysis
run_static_analysis() {
    log_section "Running Static Analysis"

    run_test "Flutter analyze" "flutter analyze --no-pub"
    run_test "Dart format check" "dart format --set-exit-if-changed --output=none ."
}

# Check code metrics
check_code_metrics() {
    log_section "Checking Code Metrics"

    log_info "Checking file sizes..."
    local large_files=$(find lib -name "*.dart" -exec wc -l {} \; | awk '$1 > 500 {print}' | wc -l)
    if [ "$large_files" -eq 0 ]; then
        log_success "No files exceed 500 lines"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "$large_files file(s) exceed 500 lines"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("File size check")
        find lib -name "*.dart" -exec wc -l {} \; | awk '$1 > 500 {print $2 " has " $1 " lines"}' | head -5
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_info "Checking function sizes..."
    # This is a simplified check - proper implementation would need more sophisticated parsing
    log_warning "Function size check skipped (requires detailed parsing)"
}

# Generate test report
generate_report() {
    log_section "Test Summary"

    local pass_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        pass_rate=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
    fi

    echo "Total Tests:   $TOTAL_TESTS"
    echo "Passed:        $GREEN$PASSED_TESTS$NC"
    echo "Failed:        $RED$FAILED_TESTS$NC"
    echo "Skipped:       $YELLOW$SKIPPED_TESTS$NC"
    echo "Pass Rate:     $pass_rate%"

    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo ""
        log_error "Failed Tests:"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $test"
        done
    fi

    echo ""

    # Generate JSON report
    local report_file="test-results-$(date +%Y%m%d-%H%M%S).json"
    cat > "$report_file" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_tests": $TOTAL_TESTS,
  "passed": $PASSED_TESTS,
  "failed": $FAILED_TESTS,
  "skipped": $SKIPPED_TESTS,
  "pass_rate": $pass_rate,
  "failed_tests": [
$(printf '    "%s"' "${FAILED_TEST_NAMES[@]}" | sed 's/" "/",\n/g')
  ]
}
EOF
    log_info "JSON report saved to: $report_file"

    # Determine exit code
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All tests passed! Ready for production deployment."
        return 0
    else
        log_error "Some tests failed. Please fix issues before deploying."
        return 1
    fi
}

# Main execution
main() {
    log_section "HexBuzz Final Integration Testing"
    log_info "Starting comprehensive test suite..."
    log_info "Date: $(date)"

    # Parse arguments
    RUN_QUICK=false
    SKIP_LOAD=false
    SKIP_BUILD=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                RUN_QUICK=true
                shift
                ;;
            --skip-load)
                SKIP_LOAD=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --quick       Run quick test suite (skip load and build tests)"
                echo "  --skip-load   Skip load testing"
                echo "  --skip-build  Skip platform build tests"
                echo "  --help        Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ "$RUN_QUICK" = true ]; then
        SKIP_LOAD=true
        SKIP_BUILD=true
        log_warning "Running in quick mode (load and build tests skipped)"
    fi

    # Run test suites
    check_prerequisites
    run_static_analysis
    check_code_metrics
    run_unit_tests
    run_widget_tests
    run_integration_tests
    run_security_tests

    if [ "$SKIP_LOAD" = false ]; then
        run_load_tests
    else
        log_warning "Skipping load tests"
    fi

    if [ "$SKIP_BUILD" = false ]; then
        test_platform_builds
    else
        log_warning "Skipping platform build tests"
    fi

    # Generate final report
    generate_report
}

# Run main function
main "$@"
