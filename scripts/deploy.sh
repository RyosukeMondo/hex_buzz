#!/bin/bash
# HexBuzz VPS Deploy Script
# Builds Flutter web and deploys to the VPS via rsync.
#
# Usage: ./scripts/deploy.sh [--skip-build] [--dry-run]
#
# Requires: flutter, rsync, ssh access to VPS

set -e
set -o pipefail

# -- Configuration --
VPS_USER="rmondo"
VPS_HOST="mondo-ai-studio.xvps.jp"
VPS_PATH="/var/www/html/hex_buzz/"
BASE_HREF="/hex_buzz/"
DEPLOY_URL="https://mondo-ai-studio.xvps.jp/hex_buzz/"

SKIP_BUILD=0
DRY_RUN=0

# -- Colors --
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# -- Parse arguments --
for arg in "$@"; do
  case "$arg" in
    --skip-build)
      SKIP_BUILD=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --help|-h)
      echo "Usage: ./scripts/deploy.sh [--skip-build] [--dry-run]"
      echo ""
      echo "Options:"
      echo "  --skip-build  Skip Flutter build, deploy existing build/web/"
      echo "  --dry-run     Show what would be deployed without transferring"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: ${arg}${NC}"
      echo "Usage: ./scripts/deploy.sh [--skip-build] [--dry-run]"
      exit 1
      ;;
  esac
done

# -- Dependency checks --
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}Required tool not found: ${1}${NC}"
    echo "$2"
    exit 1
  fi
}

check_command rsync "Install rsync to continue."

if [ "$SKIP_BUILD" -eq 0 ]; then
  check_command flutter "Install Flutter SDK: https://docs.flutter.dev/get-started/install"
fi

# -- Find project root --
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/web"

echo -e "${BOLD}=== HexBuzz VPS Deployment ===${NC}"
echo -e "${DIM}Project: ${PROJECT_ROOT}${NC}"
echo -e "${DIM}Target:  ${VPS_USER}@${VPS_HOST}:${VPS_PATH}${NC}"
echo -e "${DIM}Date:    $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"
if [ "$DRY_RUN" -eq 1 ]; then
  echo -e "${YELLOW}Mode: DRY RUN (no files will be transferred)${NC}"
fi
echo ""

# -- Build --
if [ "$SKIP_BUILD" -eq 0 ]; then
  echo -e "${CYAN}Building Flutter web (release)...${NC}"
  cd "$PROJECT_ROOT"
  flutter pub get
  flutter build web --release --base-href "$BASE_HREF"
  echo -e "${GREEN}Build complete${NC}"
  echo ""
else
  echo -e "${YELLOW}Skipping build (--skip-build)${NC}"
  echo ""
fi

# -- Verify build output --
if [ ! -d "$BUILD_DIR" ]; then
  echo -e "${RED}Build directory not found: ${BUILD_DIR}${NC}"
  echo "Run without --skip-build to create it."
  exit 1
fi

if [ ! -f "${BUILD_DIR}/index.html" ]; then
  echo -e "${RED}Build appears incomplete: index.html not found${NC}"
  exit 1
fi

FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
echo -e "${DIM}Build contains ${FILE_COUNT} files (${BUILD_SIZE})${NC}"

# -- Check SSH connectivity --
echo -e "${CYAN}Checking SSH connectivity...${NC}"
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${VPS_USER}@${VPS_HOST}" "echo ok" &>/dev/null; then
  echo -e "${RED}Cannot connect to ${VPS_USER}@${VPS_HOST}${NC}"
  echo "Check your SSH keys and network connection."
  exit 1
fi
echo -e "${GREEN}SSH connection verified${NC}"
echo ""

# -- Deploy --
echo -e "${CYAN}Deploying to VPS...${NC}"

RSYNC_ARGS=(-avz --delete --stats)
if [ "$DRY_RUN" -eq 1 ]; then
  RSYNC_ARGS+=(--dry-run)
fi

rsync "${RSYNC_ARGS[@]}" "${BUILD_DIR}/" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}"

echo ""

if [ "$DRY_RUN" -eq 1 ]; then
  echo -e "${YELLOW}Dry run complete. No files were transferred.${NC}"
  echo "Remove --dry-run to actually deploy."
else
  echo -e "${GREEN}${BOLD}Deployment complete${NC}"
  echo -e "${DIM}Deployed to: ${DEPLOY_URL}${NC}"
  echo ""

  # Quick smoke test
  echo -e "${CYAN}Running smoke test...${NC}"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "${DEPLOY_URL}" 2>/dev/null)
  if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}Smoke test passed (HTTP ${HTTP_CODE})${NC}"
  elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "${YELLOW}Could not reach ${DEPLOY_URL} (DNS/network issue)${NC}"
  else
    echo -e "${YELLOW}Smoke test returned HTTP ${HTTP_CODE}${NC}"
  fi
fi

echo ""
echo -e "${GREEN}Done.${NC}"
