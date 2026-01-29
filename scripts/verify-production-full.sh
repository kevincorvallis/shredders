#!/bin/bash

# Full Production Verification Script
# Runs backend API checks and optionally builds/tests iOS app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios/PowderTracker"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Full Production Verification${NC}"
echo -e "${BLUE}  $(date)${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Parse arguments
RUN_IOS_BUILD=false
RUN_IOS_TESTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ios-build)
            RUN_IOS_BUILD=true
            shift
            ;;
        --ios-tests)
            RUN_IOS_TESTS=true
            shift
            ;;
        --all)
            RUN_IOS_BUILD=true
            RUN_IOS_TESTS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --ios-build   Build iOS app after API checks"
            echo "  --ios-tests   Run iOS UI tests after API checks"
            echo "  --all         Run all checks (API + iOS build + tests)"
            echo "  -h, --help    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Run API checks only (fast)"
            echo "  $0 --ios-build  # Run API checks + build iOS"
            echo "  $0 --all        # Run everything"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Step 1: Backend API Verification
echo -e "${BLUE}Step 1: Backend API Verification${NC}"
echo "--------------------------------"

if [ -f "$IOS_DIR/scripts/verify-production.sh" ]; then
    "$IOS_DIR/scripts/verify-production.sh"
    API_RESULT=$?
else
    echo -e "${RED}Error: verify-production.sh not found${NC}"
    exit 1
fi

if [ $API_RESULT -ne 0 ]; then
    echo ""
    echo -e "${RED}API verification failed! Stopping.${NC}"
    exit 1
fi

echo ""

# Step 2: iOS Build (optional)
if [ "$RUN_IOS_BUILD" = true ]; then
    echo -e "${BLUE}Step 2: iOS App Build${NC}"
    echo "--------------------------------"

    cd "$IOS_DIR"

    echo "Building iOS app..."
    if xcodebuild -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -quiet \
        build 2>&1; then
        echo -e "${GREEN}✓${NC} iOS app built successfully"
    else
        echo -e "${RED}✗${NC} iOS app build failed"
        exit 1
    fi

    echo ""
fi

# Step 3: iOS UI Tests (optional)
if [ "$RUN_IOS_TESTS" = true ]; then
    echo -e "${BLUE}Step 3: iOS UI Tests${NC}"
    echo "--------------------------------"

    cd "$IOS_DIR"

    echo "Running UI tests..."
    if xcodebuild test \
        -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -only-testing:PowderTrackerUITests \
        -quiet 2>&1; then
        echo -e "${GREEN}✓${NC} All UI tests passed"
    else
        echo -e "${RED}✗${NC} UI tests failed"
        exit 1
    fi

    echo ""
fi

# Summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${GREEN}✓${NC} Backend API checks: Passed"

if [ "$RUN_IOS_BUILD" = true ]; then
    echo -e "${GREEN}✓${NC} iOS app build: Passed"
fi

if [ "$RUN_IOS_TESTS" = true ]; then
    echo -e "${GREEN}✓${NC} iOS UI tests: Passed"
fi

echo ""
echo -e "${GREEN}Production verification complete!${NC}"
echo ""

# Provide next steps
if [ "$RUN_IOS_BUILD" = false ] && [ "$RUN_IOS_TESTS" = false ]; then
    echo -e "${YELLOW}Tip:${NC} Run with --ios-build or --all to also verify iOS app"
fi
