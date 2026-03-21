#!/bin/bash
# HexBuzz Autonomous Screen Inspector
# Navigates to every known route, captures screen state, checks for issues,
# and generates a structured JSON diagnostic report.
#
# Usage: ./scripts/inspect_and_report.sh [base_url] [output_dir]
# Default: http://localhost:8080, reports go to current directory
#
# Requires: curl, jq
# The app must be running with ENABLE_API=true and diagnostic endpoints enabled

set -o pipefail

# -- Configuration --
BASE="${1:-http://localhost:8080}"
OUTPUT_DIR="${2:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${OUTPUT_DIR}/diagnostic_report_${TIMESTAMP}.json"
NAV_DELAY="${NAV_DELAY:-0.5}"

# -- Colors --
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

TOTAL_LAYOUT_ISSUES=0
TOTAL_A11Y_ISSUES=0
ROUTES_INSPECTED=0
ROUTES_FAILED=0

# All known routes from NavigationValidator._knownRoutes plus additional app routes
ROUTES=(
  "/"
  "/auth"
  "/levels"
  "/game"
  "/daily-challenge"
  "/leaderboard"
)

# -- Helpers --
check_deps() {
  for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${RED}Missing required tool: ${cmd}${NC}"
      exit 1
    fi
  done
}

check_server() {
  echo -e "${CYAN}Checking server at ${BASE}...${NC}"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE}/api/health" 2>/dev/null)
  if [ "$?" -ne 0 ] || [ "$http_code" = "000" ]; then
    echo -e "${RED}Cannot connect to ${BASE}${NC}"
    echo "Make sure the app is running with ENABLE_API=true"
    exit 1
  fi
  echo -e "${GREEN}Server is reachable${NC}"
}

check_diagnostics() {
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE}/api/debug/screen" 2>/dev/null)
  if [ "$http_code" = "404" ]; then
    echo -e "${RED}Diagnostic endpoints not available (404)${NC}"
    echo "The app must have navigatorKey configured for diagnostic endpoints."
    exit 1
  fi
  if [ "$http_code" = "503" ]; then
    echo -e "${YELLOW}Diagnostic endpoints return 503 (no active context)${NC}"
    echo "The app may not have a visible screen. Continuing anyway..."
  fi
}

safe_curl() {
  local url="$1"
  local result
  result=$(curl -s --connect-timeout 10 --max-time 30 "$url" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$result" ]; then
    echo '{"error":"connection_failed"}'
    return 1
  fi
  # Validate JSON
  if ! echo "$result" | jq '.' &>/dev/null; then
    echo '{"error":"invalid_json"}'
    return 1
  fi
  echo "$result"
}

safe_post() {
  local url="$1"
  local body="$2"
  local result
  result=$(curl -s --connect-timeout 10 --max-time 30 -X POST \
    -H "Content-Type: application/json" -d "$body" "$url" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$result" ]; then
    echo '{"error":"connection_failed"}'
    return 1
  fi
  if ! echo "$result" | jq '.' &>/dev/null; then
    echo '{"error":"invalid_json"}'
    return 1
  fi
  echo "$result"
}

# -- Main --
check_deps
check_server
check_diagnostics

echo -e "${BOLD}=== HexBuzz Autonomous Screen Inspector ===${NC}"
echo -e "${DIM}Target: ${BASE}${NC}"
echo -e "${DIM}Report: ${REPORT_FILE}${NC}"
echo -e "${DIM}Date:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR" 2>/dev/null

# Collect known routes from the API itself
echo -e "${CYAN}Fetching known routes from API...${NC}"
API_ROUTES=$(safe_curl "${BASE}/api/debug/routes")
API_ROUTE_COUNT=$(echo "$API_ROUTES" | jq '.routeCount // 0' 2>/dev/null)
echo -e "  ${DIM}API reports ${API_ROUTE_COUNT:-0} known routes${NC}"

# If the API returns routes, merge them with our hardcoded list
if [ "${API_ROUTE_COUNT:-0}" -gt 0 ] 2>/dev/null; then
  EXTRA_ROUTES=$(echo "$API_ROUTES" | jq -r '.knownRoutes[]?' 2>/dev/null)
  while IFS= read -r r; do
    if [ -n "$r" ]; then
      # Check if already in our list
      found=0
      for existing in "${ROUTES[@]}"; do
        if [ "$existing" = "$r" ]; then
          found=1
          break
        fi
      done
      if [ "$found" -eq 0 ]; then
        ROUTES+=("$r")
      fi
    fi
  done <<< "$EXTRA_ROUTES"
fi

echo -e "  ${DIM}Will inspect ${#ROUTES[@]} routes${NC}"
echo ""

# Build the report as a temp file, then assemble
SCREENS_FILE=$(mktemp)
echo '[]' > "$SCREENS_FILE"

for route in "${ROUTES[@]}"; do
  echo -ne "  Inspecting ${BOLD}${route}${NC}... "

  # Navigate to route
  NAV_RESULT=$(safe_post "${BASE}/api/debug/navigate" "{\"route\":\"${route}\"}")
  NAV_SUCCESS=$(echo "$NAV_RESULT" | jq -r '.success // false' 2>/dev/null)

  if [ "$NAV_SUCCESS" = "false" ]; then
    NAV_ERROR=$(echo "$NAV_RESULT" | jq -r '.error // .message // "unknown"' 2>/dev/null)
    echo -e "${YELLOW}navigation failed: ${NAV_ERROR}${NC}"
    ROUTES_FAILED=$((ROUTES_FAILED + 1))

    # Still add to report with error status
    ENTRY=$(jq -n \
      --arg route "$route" \
      --arg error "$NAV_ERROR" \
      '{route: $route, status: "navigation_failed", error: $error, screen: null, layout_issues: [], accessibility_issues: []}')

    UPDATED=$(jq --argjson entry "$ENTRY" '. + [$entry]' "$SCREENS_FILE")
    echo "$UPDATED" > "$SCREENS_FILE"
    continue
  fi

  # Wait for navigation to settle
  sleep "$NAV_DELAY"

  ROUTES_INSPECTED=$((ROUTES_INSPECTED + 1))

  # Capture screen state
  SCREEN=$(safe_curl "${BASE}/api/debug/screen")

  # Check layout issues
  LAYOUT=$(safe_curl "${BASE}/api/debug/layout-issues")
  LAYOUT_COUNT=$(echo "$LAYOUT" | jq '.issueCount // 0' 2>/dev/null)
  TOTAL_LAYOUT_ISSUES=$((TOTAL_LAYOUT_ISSUES + ${LAYOUT_COUNT:-0}))

  # Check accessibility
  A11Y=$(safe_curl "${BASE}/api/debug/accessibility")
  A11Y_COUNT=$(echo "$A11Y" | jq '.issueCount // 0' 2>/dev/null)
  TOTAL_A11Y_ISSUES=$((TOTAL_A11Y_ISSUES + ${A11Y_COUNT:-0}))

  # Status indicator
  if [ "${LAYOUT_COUNT:-0}" -gt 0 ] || [ "${A11Y_COUNT:-0}" -gt 0 ]; then
    echo -e "${YELLOW}layout:${LAYOUT_COUNT:-0} a11y:${A11Y_COUNT:-0}${NC}"
  else
    echo -e "${GREEN}clean${NC}"
  fi

  # Build entry
  ENTRY=$(jq -n \
    --arg route "$route" \
    --argjson screen "$SCREEN" \
    --argjson layout "$LAYOUT" \
    --argjson a11y "$A11Y" \
    --argjson layout_count "${LAYOUT_COUNT:-0}" \
    --argjson a11y_count "${A11Y_COUNT:-0}" \
    '{
      route: $route,
      status: "inspected",
      screen: $screen,
      layout_issues: $layout,
      layout_issue_count: $layout_count,
      accessibility_issues: $a11y,
      accessibility_issue_count: $a11y_count
    }')

  UPDATED=$(jq --argjson entry "$ENTRY" '. + [$entry]' "$SCREENS_FILE")
  echo "$UPDATED" > "$SCREENS_FILE"
done

# Navigate back to root
echo ""
echo -e "${DIM}Navigating back to /...${NC}"
safe_post "${BASE}/api/debug/navigate" '{"route":"/"}' > /dev/null 2>&1

# Build final report
echo -e "${CYAN}Generating report...${NC}"

SCREENS_DATA=$(cat "$SCREENS_FILE")
rm -f "$SCREENS_FILE"

FINAL_REPORT=$(jq -n \
  --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg base_url "$BASE" \
  --argjson routes_inspected "$ROUTES_INSPECTED" \
  --argjson routes_failed "$ROUTES_FAILED" \
  --argjson total_routes "${#ROUTES[@]}" \
  --argjson total_layout "$TOTAL_LAYOUT_ISSUES" \
  --argjson total_a11y "$TOTAL_A11Y_ISSUES" \
  --argjson screens "$SCREENS_DATA" \
  '{
    meta: {
      timestamp: $timestamp,
      base_url: $base_url,
      tool: "HexBuzz Autonomous Screen Inspector"
    },
    summary: {
      total_routes: $total_routes,
      routes_inspected: $routes_inspected,
      routes_failed: $routes_failed,
      total_layout_issues: $total_layout,
      total_accessibility_issues: $total_a11y,
      total_issues: ($total_layout + $total_a11y)
    },
    screens: $screens
  }')

echo "$FINAL_REPORT" > "$REPORT_FILE"

# Print summary
echo ""
echo -e "${BOLD}======================================${NC}"
echo -e "${BOLD}       INSPECTION REPORT${NC}"
echo -e "${BOLD}======================================${NC}"
echo -e "  Routes inspected:     ${ROUTES_INSPECTED} / ${#ROUTES[@]}"
if [ "$ROUTES_FAILED" -gt 0 ]; then
  echo -e "  ${RED}Routes failed:        ${ROUTES_FAILED}${NC}"
fi
echo -e "  Layout issues:        ${TOTAL_LAYOUT_ISSUES}"
echo -e "  Accessibility issues: ${TOTAL_A11Y_ISSUES}"
TOTAL_ISSUES=$((TOTAL_LAYOUT_ISSUES + TOTAL_A11Y_ISSUES))
echo -e "  ${BOLD}Total issues:           ${TOTAL_ISSUES}${NC}"
echo -e "${BOLD}======================================${NC}"
echo ""

# Per-route breakdown if there are issues
if [ "$TOTAL_ISSUES" -gt 0 ]; then
  echo -e "${BOLD}Per-route breakdown:${NC}"
  echo "$FINAL_REPORT" | jq -r '
    .screens[]
    | select(.status == "inspected")
    | select((.layout_issue_count // 0) > 0 or (.accessibility_issue_count // 0) > 0)
    | "  \(.route): layout=\(.layout_issue_count // 0) a11y=\(.accessibility_issue_count // 0)"
  ' 2>/dev/null
  echo ""
fi

echo -e "${DIM}Full report: ${REPORT_FILE}${NC}"

if [ "$TOTAL_ISSUES" -gt 0 ]; then
  echo -e "${YELLOW}Issues were detected. Review the report for details.${NC}"
  exit 1
else
  echo -e "${GREEN}All screens passed inspection.${NC}"
  exit 0
fi
