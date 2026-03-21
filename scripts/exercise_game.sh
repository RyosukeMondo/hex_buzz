#!/bin/bash
# HexBuzz Business Logic Exerciser
# Plays through a complete game flow via the REST API.
# Exercises: reset -> get state -> make moves -> check progress -> diagnostics
#
# Usage: ./scripts/exercise_game.sh [base_url]
# Default: http://localhost:8080
#
# Requires: curl, jq
# The app must be running with ENABLE_API=true

set -o pipefail

# -- Configuration --
BASE="${1:-http://localhost:8080}"

# -- Colors --
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

STEP=0
ERRORS=0

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
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE}/api/health" 2>/dev/null)
  if [ "$?" -ne 0 ] || [ "$http_code" = "000" ]; then
    echo -e "${RED}Cannot connect to ${BASE}${NC}"
    echo "Make sure the app is running with ENABLE_API=true"
    exit 1
  fi
}

step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BOLD}${CYAN}Step ${STEP}: $1${NC}"
}

api_get() {
  local path="$1"
  local result
  result=$(curl -s --connect-timeout 10 --max-time 30 "${BASE}${path}" 2>&1)
  if [ $? -ne 0 ]; then
    echo -e "${RED}  Connection error for GET ${path}${NC}"
    ERRORS=$((ERRORS + 1))
    echo "{}"
    return 1
  fi
  # Validate it's JSON
  if ! echo "$result" | jq '.' &>/dev/null; then
    echo -e "${RED}  Invalid JSON from GET ${path}${NC}"
    ERRORS=$((ERRORS + 1))
    echo "{}"
    return 1
  fi
  echo "$result"
}

api_post() {
  local path="$1"
  local body="$2"
  local curl_args=(-s --connect-timeout 10 --max-time 30 -X POST)
  if [ -n "$body" ]; then
    curl_args+=(-H "Content-Type: application/json" -d "$body")
  fi
  local result
  result=$(curl "${curl_args[@]}" "${BASE}${path}" 2>&1)
  if [ $? -ne 0 ]; then
    echo -e "${RED}  Connection error for POST ${path}${NC}"
    ERRORS=$((ERRORS + 1))
    echo "{}"
    return 1
  fi
  if ! echo "$result" | jq '.' &>/dev/null; then
    echo -e "${RED}  Invalid JSON from POST ${path}${NC}"
    ERRORS=$((ERRORS + 1))
    echo "{}"
    return 1
  fi
  echo "$result"
}

print_json() {
  local label="$1"
  local data="$2"
  local query="${3:-.}"
  local extracted
  extracted=$(echo "$data" | jq -r "$query" 2>/dev/null)
  if [ $? -eq 0 ] && [ "$extracted" != "null" ]; then
    echo -e "  ${DIM}${label}:${NC} ${extracted}"
  else
    echo -e "  ${DIM}${label}:${NC} ${YELLOW}(unavailable)${NC}"
  fi
}

assert_field() {
  local data="$1"
  local field="$2"
  local expected="$3"
  local actual
  actual=$(echo "$data" | jq -r "$field" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    echo -e "  ${GREEN}OK${NC} ${field} = ${actual}"
  else
    echo -e "  ${RED}MISMATCH${NC} ${field} = ${actual} (expected ${expected})"
    ERRORS=$((ERRORS + 1))
  fi
}

# -- Main --
check_deps
check_server

echo -e "${BOLD}=== HexBuzz Business Logic Exerciser ===${NC}"
echo -e "${DIM}Target: ${BASE}${NC}"
echo -e "${DIM}Date:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"

# -----------------------------------------------
step "Check health"
# -----------------------------------------------
HEALTH=$(api_get "/api/health")
assert_field "$HEALTH" ".status" "ok"
print_json "Timestamp" "$HEALTH" ".timestamp"

# -----------------------------------------------
step "Reset game to clean state"
# -----------------------------------------------
RESET=$(api_post "/api/game/reset")
assert_field "$RESET" ".success" "true"
print_json "Mode" "$RESET" ".state.mode"
print_json "Path length" "$RESET" ".state.path | length"

# -----------------------------------------------
step "Get initial game state"
# -----------------------------------------------
STATE=$(api_get "/api/game/state")
print_json "Level ID" "$STATE" ".level.id"
print_json "Level size" "$STATE" ".level.size"
print_json "Checkpoint count" "$STATE" ".level.checkpointCount"
print_json "Is started" "$STATE" ".isStarted"
print_json "Is complete" "$STATE" ".isComplete"
print_json "Path length" "$STATE" ".path | length"

CELL_COUNT=$(echo "$STATE" | jq '.level.cells | length' 2>/dev/null)
echo -e "  ${DIM}Total cells:${NC} ${CELL_COUNT:-0}"

# -----------------------------------------------
step "Extract cells and attempt moves"
# -----------------------------------------------
# Get first few cells from the level to try moving to them
CELLS=$(echo "$STATE" | jq -c '.level.cells // []' 2>/dev/null)
if [ "$CELLS" = "[]" ] || [ -z "$CELLS" ]; then
  echo -e "  ${YELLOW}No cells in level data, skipping move attempts${NC}"
else
  # Try up to 5 cells
  MOVE_COUNT=0
  MAX_MOVES=5
  echo "$CELLS" | jq -c '.[]' 2>/dev/null | head -n "$MAX_MOVES" | while IFS= read -r cell; do
    MOVE_COUNT=$((MOVE_COUNT + 1))
    Q=$(echo "$cell" | jq -r '.q' 2>/dev/null)
    R=$(echo "$cell" | jq -r '.r' 2>/dev/null)
    if [ "$Q" = "null" ] || [ "$R" = "null" ]; then
      continue
    fi
    echo -e "  ${DIM}Move ${MOVE_COUNT}: trying (${Q}, ${R})...${NC}"
    MOVE_RESULT=$(api_post "/api/game/move" "{\"q\":${Q},\"r\":${R}}")
    SUCCESS=$(echo "$MOVE_RESULT" | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" = "true" ]; then
      echo -e "    ${GREEN}Move accepted${NC}"
      IS_WIN=$(echo "$MOVE_RESULT" | jq -r '.isWin // false' 2>/dev/null)
      if [ "$IS_WIN" = "true" ]; then
        echo -e "    ${GREEN}${BOLD}Level complete!${NC}"
      fi
    else
      ERROR=$(echo "$MOVE_RESULT" | jq -r '.message // .error // "unknown"' 2>/dev/null)
      echo -e "    ${YELLOW}Move rejected: ${ERROR}${NC}"
    fi
  done
fi

# -----------------------------------------------
step "Check game state after moves"
# -----------------------------------------------
STATE_AFTER=$(api_get "/api/game/state")
print_json "Is started" "$STATE_AFTER" ".isStarted"
print_json "Is complete" "$STATE_AFTER" ".isComplete"
print_json "Path length" "$STATE_AFTER" ".path | length"
print_json "Current cell" "$STATE_AFTER" '.currentCell | if . then "(\(.q), \(.r))" else "none" end'
print_json "Next checkpoint" "$STATE_AFTER" ".nextCheckpoint"
print_json "Elapsed time (ms)" "$STATE_AFTER" ".elapsedTimeMs"

VISITED=$(echo "$STATE_AFTER" | jq '.visitedCells | length' 2>/dev/null)
echo -e "  ${DIM}Visited cells:${NC} ${VISITED:-0}"

# -----------------------------------------------
step "Test invalid move (error handling)"
# -----------------------------------------------
BAD_MOVE=$(api_post "/api/game/move" '{"q":999,"r":999}')
BAD_SUCCESS=$(echo "$BAD_MOVE" | jq -r '.success' 2>/dev/null)
if [ "$BAD_SUCCESS" = "false" ]; then
  echo -e "  ${GREEN}OK${NC} Invalid move correctly rejected"
  print_json "Error" "$BAD_MOVE" ".error"
else
  echo -e "  ${YELLOW}Unexpected: invalid move was accepted${NC}"
fi

# -----------------------------------------------
step "Check progress (if available)"
# -----------------------------------------------
PROGRESS=$(api_get "/api/progress/")
PROG_STATUS=$(echo "$PROGRESS" | jq -r '.error // empty' 2>/dev/null)
if [ -n "$PROG_STATUS" ]; then
  echo -e "  ${YELLOW}Progress endpoint not available: ${PROG_STATUS}${NC}"
else
  print_json "Total stars" "$PROGRESS" ".totalStars"
  print_json "Completed levels" "$PROGRESS" ".completedLevels"
  print_json "Highest unlocked" "$PROGRESS" ".highestUnlockedLevel"
fi

# -----------------------------------------------
step "Check diagnostic screen state (if available)"
# -----------------------------------------------
SCREEN=$(api_get "/api/debug/screen")
SCREEN_ERR=$(echo "$SCREEN" | jq -r '.error // empty' 2>/dev/null)
if [ -n "$SCREEN_ERR" ]; then
  echo -e "  ${YELLOW}Screen diagnostics not available: ${SCREEN_ERR}${NC}"
else
  print_json "Current route" "$SCREEN" ".route"
  TEXT_COUNT=$(echo "$SCREEN" | jq '.visibleText | length' 2>/dev/null)
  echo -e "  ${DIM}Visible text items:${NC} ${TEXT_COUNT:-0}"
  TAPPABLE_COUNT=$(echo "$SCREEN" | jq '.tappableCount' 2>/dev/null)
  echo -e "  ${DIM}Tappable elements:${NC} ${TAPPABLE_COUNT:-0}"
fi

# -----------------------------------------------
step "Check for layout issues"
# -----------------------------------------------
LAYOUT=$(api_get "/api/debug/layout-issues")
LAYOUT_ERR=$(echo "$LAYOUT" | jq -r '.error // empty' 2>/dev/null)
if [ -n "$LAYOUT_ERR" ]; then
  echo -e "  ${YELLOW}Layout diagnostics not available: ${LAYOUT_ERR}${NC}"
else
  ISSUE_COUNT=$(echo "$LAYOUT" | jq '.issueCount' 2>/dev/null)
  if [ "${ISSUE_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "  ${RED}Layout issues found: ${ISSUE_COUNT}${NC}"
    echo "$LAYOUT" | jq -r '.issues[]? | "    - \(.type // "unknown"): \(.message // "no details")"' 2>/dev/null
  else
    echo -e "  ${GREEN}No layout issues${NC}"
  fi
fi

# -----------------------------------------------
step "Check accessibility"
# -----------------------------------------------
A11Y=$(api_get "/api/debug/accessibility")
A11Y_ERR=$(echo "$A11Y" | jq -r '.error // empty' 2>/dev/null)
if [ -n "$A11Y_ERR" ]; then
  echo -e "  ${YELLOW}Accessibility audit not available: ${A11Y_ERR}${NC}"
else
  A11Y_COUNT=$(echo "$A11Y" | jq '.issueCount' 2>/dev/null)
  if [ "${A11Y_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "  ${YELLOW}Accessibility issues: ${A11Y_COUNT}${NC}"
    echo "$A11Y" | jq -r '.issues[:5][]? | "    - \(.severity // "info"): \(.message // "no details")"' 2>/dev/null
    if [ "${A11Y_COUNT:-0}" -gt 5 ] 2>/dev/null; then
      echo -e "    ${DIM}... and $((A11Y_COUNT - 5)) more${NC}"
    fi
  else
    echo -e "  ${GREEN}No accessibility issues${NC}"
  fi
fi

# -----------------------------------------------
step "Run full validation"
# -----------------------------------------------
VALIDATE=$(api_get "/api/debug/validate-all")
VALIDATE_ERR=$(echo "$VALIDATE" | jq -r '.error // empty' 2>/dev/null)
if [ -n "$VALIDATE_ERR" ]; then
  echo -e "  ${YELLOW}Full validation not available: ${VALIDATE_ERR}${NC}"
else
  print_json "Total issues" "$VALIDATE" ".summary.totalIssues"
  print_json "Layout issues" "$VALIDATE" ".summary.layoutIssueCount"
  print_json "Accessibility issues" "$VALIDATE" ".summary.accessibilityIssueCount"
  print_json "Visible text count" "$VALIDATE" ".summary.visibleTextCount"
  print_json "Tappable elements" "$VALIDATE" ".summary.tappableElementCount"
  print_json "Route count" "$VALIDATE" ".summary.routeCount"
fi

# -----------------------------------------------
step "Reset game (cleanup)"
# -----------------------------------------------
FINAL_RESET=$(api_post "/api/game/reset")
assert_field "$FINAL_RESET" ".success" "true"

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo ""
echo -e "${BOLD}==============================${NC}"
echo -e "${BOLD}    EXERCISER SUMMARY${NC}"
echo -e "${BOLD}==============================${NC}"
echo -e "  Steps completed: ${STEP}"
if [ "$ERRORS" -gt 0 ]; then
  echo -e "  ${RED}Errors: ${ERRORS}${NC}"
else
  echo -e "  ${GREEN}Errors: 0${NC}"
fi
echo -e "${BOLD}==============================${NC}"

if [ "$ERRORS" -gt 0 ]; then
  echo -e "${YELLOW}Some issues were detected during the exercise.${NC}"
  exit 1
else
  echo -e "${GREEN}Business logic exercise completed successfully.${NC}"
  exit 0
fi
