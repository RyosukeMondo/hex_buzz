#!/bin/bash
# HexBuzz API Endpoint Exerciser
# Calls every REST API endpoint and validates responses.
# Usage: ./scripts/test_api.sh [base_url]
# Default: http://localhost:8080
#
# Requires: curl, jq
# The app must be running with ENABLE_API=true

set -o pipefail

# -- Configuration --
BASE="${1:-http://localhost:8080}"
PASS=0
FAIL=0
SKIP=0
TOTAL=0
VERBOSE="${VERBOSE:-0}"

# -- Colors --
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# -- Dependency check --
check_deps() {
  local missing=0
  for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${RED}Missing required tool: ${cmd}${NC}"
      missing=1
    fi
  done
  if [ "$missing" -eq 1 ]; then
    echo "Install missing tools and try again."
    exit 1
  fi
}

# -- Connectivity check --
check_server() {
  echo -e "${CYAN}Checking server at ${BASE}...${NC}"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE}/api/health" 2>/dev/null)
  if [ "$?" -ne 0 ] || [ "$http_code" = "000" ]; then
    echo -e "${RED}Cannot connect to ${BASE}${NC}"
    echo "Make sure the app is running with ENABLE_API=true"
    exit 1
  fi
  echo -e "${GREEN}Server is reachable (HTTP ${http_code})${NC}"
  echo ""
}

# -- Core test function --
# test_endpoint METHOD PATH [BODY] [EXPECTED_STATUS]
# EXPECTED_STATUS can be:
#   200       - expect exactly 200
#   200,400   - expect 200 or 400 (multiple acceptable codes)
#   any       - any status is acceptable (endpoint existence test)
test_endpoint() {
  local method="$1"
  local path="$2"
  local body="$3"
  local expect_status="${4:-200}"
  local url="${BASE}${path}"

  TOTAL=$((TOTAL + 1))

  local curl_args=(-s -w '\n%{http_code}' --connect-timeout 10 --max-time 30)
  curl_args+=(-X "$method")

  if [ -n "$body" ]; then
    curl_args+=(-H "Content-Type: application/json" -d "$body")
  fi

  local raw_output
  raw_output=$(curl "${curl_args[@]}" "$url" 2>&1)
  local curl_exit=$?

  if [ "$curl_exit" -ne 0 ]; then
    FAIL=$((FAIL + 1))
    printf "${RED}FAIL${NC} %-6s %-50s ${DIM}(connection error: curl exit %d)${NC}\n" \
      "$method" "$path" "$curl_exit"
    return
  fi

  # Split response body and status code
  local http_code
  http_code=$(echo "$raw_output" | tail -n1)
  local response_body
  response_body=$(echo "$raw_output" | sed '$d')

  # Check if status matches expected
  local matched=0
  if [ "$expect_status" = "any" ]; then
    matched=1
  else
    IFS=',' read -ra codes <<< "$expect_status"
    for code in "${codes[@]}"; do
      if [ "$http_code" = "$code" ]; then
        matched=1
        break
      fi
    done
  fi

  if [ "$matched" -eq 1 ]; then
    PASS=$((PASS + 1))
    printf "${GREEN}PASS${NC} %-6s %-50s ${DIM}HTTP %s${NC}\n" \
      "$method" "$path" "$http_code"
  else
    FAIL=$((FAIL + 1))
    printf "${RED}FAIL${NC} %-6s %-50s ${DIM}HTTP %s (expected %s)${NC}\n" \
      "$method" "$path" "$http_code" "$expect_status"
  fi

  # Verbose: show response body
  if [ "$VERBOSE" = "1" ] && [ -n "$response_body" ]; then
    echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
    echo ""
  fi
}

# -- Section header --
section() {
  echo ""
  echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
}

# -- Main --
check_deps
check_server

echo -e "${BOLD}HexBuzz API Endpoint Exerciser${NC}"
echo -e "${DIM}Target: ${BASE}${NC}"
echo -e "${DIM}Date:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"
echo ""

# -----------------------------------------------
section "Health"
# -----------------------------------------------
test_endpoint GET "/api/health"

# -----------------------------------------------
section "Game Endpoints (/api/game)"
# -----------------------------------------------
test_endpoint GET  "/api/game/state"
test_endpoint POST "/api/game/reset"
test_endpoint POST "/api/game/move" '{"q":0,"r":0}' "200,400"

# Error paths
test_endpoint POST "/api/game/move" '' "400"
test_endpoint POST "/api/game/move" '{"q":0}' "400"
test_endpoint POST "/api/game/move" '{"q":"a","r":"b"}' "400"
test_endpoint POST "/api/game/move" 'not-json' "400,415"

# -----------------------------------------------
section "Level Endpoints (/api/level)"
# -----------------------------------------------
test_endpoint POST "/api/level/validate" '{"id":"test","size":3,"cells":[],"walls":[]}' "200,400"

# Error paths
test_endpoint POST "/api/level/validate" '' "400"
test_endpoint POST "/api/level/validate" 'bad-json' "400,415"

# -----------------------------------------------
section "Progress Endpoints (/api/progress)"
# -----------------------------------------------
test_endpoint GET  "/api/progress/" "200,404"
test_endpoint POST "/api/progress/complete" '{"level":0,"timeMs":5000}' "200,400,404"
test_endpoint POST "/api/progress/reset" "" "200,404"

# Error paths
test_endpoint POST "/api/progress/complete" '' "400,404"
test_endpoint POST "/api/progress/complete" '{"level":-1,"timeMs":5000}' "400,404"
test_endpoint POST "/api/progress/complete" '{"timeMs":5000}' "400,404"
test_endpoint POST "/api/progress/complete" '{"level":0}' "400,404"

# -----------------------------------------------
section "Auth Endpoints (/api/auth)"
# -----------------------------------------------
test_endpoint GET  "/api/auth/me" "200,404"
test_endpoint POST "/api/auth/google" "" "200,400,404"
test_endpoint POST "/api/auth/logout" "" "200,400,404"

# -----------------------------------------------
section "Leaderboard Endpoints (/api/leaderboard)"
# -----------------------------------------------
test_endpoint GET  "/api/leaderboard/" "200,404"
test_endpoint GET  "/api/leaderboard/?limit=10" "200,404"
test_endpoint GET  "/api/leaderboard/?limit=10&offset=0" "200,404"
test_endpoint GET  "/api/leaderboard/daily" "200,404"
test_endpoint GET  "/api/leaderboard/daily?date=2025-01-01&limit=5" "200,400,404"
test_endpoint GET  "/api/leaderboard/rank/test-user-id" "200,404"
test_endpoint POST "/api/leaderboard/scores" '{"userId":"test","stars":3}' "200,400,401,404"

# Error paths
test_endpoint POST "/api/leaderboard/scores" '' "400,401,404"
test_endpoint POST "/api/leaderboard/scores" '{"stars":3}' "400,401,404"

# -----------------------------------------------
section "Daily Challenge Endpoints (/api/daily-challenge)"
# -----------------------------------------------
test_endpoint GET  "/api/daily-challenge/" "200,404"
test_endpoint GET  "/api/daily-challenge/leaderboard" "200,404"
test_endpoint GET  "/api/daily-challenge/leaderboard?date=2025-01-01&limit=5" "200,400,404"
test_endpoint POST "/api/daily-challenge/complete" \
  '{"userId":"test","stars":2,"completionTimeMs":3000}' "200,400,401,404"
test_endpoint GET  "/api/daily-challenge/completed/test-user-id" "200,404"

# Error paths
test_endpoint POST "/api/daily-challenge/complete" '' "400,401,404"
test_endpoint POST "/api/daily-challenge/complete" '{"userId":"test"}' "400,401,404"
test_endpoint POST "/api/daily-challenge/complete" '{"userId":"test","stars":5,"completionTimeMs":1000}' "400,401,404"

# -----------------------------------------------
section "Diagnostic Endpoints (/api/debug)"
# -----------------------------------------------
test_endpoint GET  "/api/debug/screen" "200,503,404"
test_endpoint GET  "/api/debug/widget-tree" "200,503,404"
test_endpoint GET  "/api/debug/widget-tree?depth=5" "200,503,404"
test_endpoint GET  "/api/debug/layout-issues" "200,503,404"
test_endpoint GET  "/api/debug/accessibility" "200,503,404"
test_endpoint GET  "/api/debug/providers" "200,503,404"
test_endpoint GET  "/api/debug/routes" "200,503,404"
test_endpoint GET  "/api/debug/validate-all" "200,503,404"
test_endpoint POST "/api/debug/navigate" '{"route":"/"}' "200,400,503,404"
test_endpoint POST "/api/debug/tap" '{"text":"Start"}' "200,400,404,503"

# Error paths
test_endpoint POST "/api/debug/navigate" '' "400,503,404"
test_endpoint POST "/api/debug/navigate" '{"route":""}' "400,503,404"
test_endpoint POST "/api/debug/tap" '' "400,503,404"
test_endpoint POST "/api/debug/tap" '{"wrong":"field"}' "400,503,404"

# -----------------------------------------------
section "Edge Cases"
# -----------------------------------------------
test_endpoint GET  "/api/nonexistent" "404"
test_endpoint POST "/api/health" "" "404,405"

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo ""
echo -e "${BOLD}==============================${NC}"
echo -e "${BOLD}       TEST SUMMARY${NC}"
echo -e "${BOLD}==============================${NC}"
echo -e "  Total:   ${TOTAL}"
echo -e "  ${GREEN}Passed:  ${PASS}${NC}"
echo -e "  ${RED}Failed:  ${FAIL}${NC}"
if [ "$SKIP" -gt 0 ]; then
  echo -e "  ${YELLOW}Skipped: ${SKIP}${NC}"
fi
echo -e "${BOLD}==============================${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed.${NC}"
  exit 0
fi
