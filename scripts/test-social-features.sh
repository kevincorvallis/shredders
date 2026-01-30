#!/bin/bash

#
# test-social-features.sh
#
# End-to-end test suite for Event Social Features
# Runs unit tests, API tests, and UI tests
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_PROJECT="$PROJECT_ROOT/ios/PowderTracker"
SIMULATOR_NAME="iPhone 16"
API_BASE_URL="${TEST_API_URL:-http://localhost:3000}"

# Test results
UNIT_TESTS_PASSED=false
API_TESTS_PASSED=false
UI_TESTS_PASSED=false

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Event Social Features Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse arguments
RUN_UNIT=true
RUN_API=true
RUN_UI=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_API=false
            RUN_UI=false
            shift
            ;;
        --api-only)
            RUN_UNIT=false
            RUN_UI=false
            shift
            ;;
        --ui-only)
            RUN_UNIT=false
            RUN_API=false
            RUN_UI=true
            shift
            ;;
        --with-ui)
            RUN_UI=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --unit-only    Run only unit tests"
            echo "  --api-only     Run only API tests"
            echo "  --ui-only      Run only UI tests"
            echo "  --with-ui      Include UI tests (slower)"
            echo "  --verbose, -v  Verbose output"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Function to run iOS unit tests
run_unit_tests() {
    echo -e "${YELLOW}Running iOS Unit Tests...${NC}"
    echo ""

    cd "$IOS_PROJECT"

    if $VERBOSE; then
        xcodebuild test \
            -scheme PowderTracker \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
            -only-testing:PowderTrackerTests/EventDiscussionViewModelTests \
            -only-testing:PowderTrackerTests/EventActivityViewModelTests \
            -only-testing:PowderTrackerTests/EventPhotosViewModelTests \
            2>&1
    else
        xcodebuild test \
            -scheme PowderTracker \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
            -only-testing:PowderTrackerTests/EventDiscussionViewModelTests \
            -only-testing:PowderTrackerTests/EventActivityViewModelTests \
            -only-testing:PowderTrackerTests/EventPhotosViewModelTests \
            -quiet 2>&1 | tail -20
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Unit tests passed${NC}"
        UNIT_TESTS_PASSED=true
    else
        echo -e "${RED}✗ Unit tests failed${NC}"
        UNIT_TESTS_PASSED=false
    fi

    echo ""
}

# Function to run API tests
run_api_tests() {
    echo -e "${YELLOW}Running API Tests...${NC}"
    echo ""

    cd "$PROJECT_ROOT"

    # Check if vitest is available
    if ! command -v npx &> /dev/null; then
        echo -e "${RED}npx not found. Skipping API tests.${NC}"
        return
    fi

    # Run API tests
    if $VERBOSE; then
        npx vitest run \
            src/app/api/events/\[id\]/comments/__tests__/route.test.ts \
            src/app/api/events/\[id\]/activity/__tests__/route.test.ts \
            src/app/api/events/\[id\]/photos/__tests__/route.test.ts \
            2>&1
    else
        npx vitest run \
            src/app/api/events/\[id\]/comments/__tests__/route.test.ts \
            src/app/api/events/\[id\]/activity/__tests__/route.test.ts \
            src/app/api/events/\[id\]/photos/__tests__/route.test.ts \
            --reporter=dot 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ API tests passed${NC}"
        API_TESTS_PASSED=true
    else
        echo -e "${RED}✗ API tests failed${NC}"
        API_TESTS_PASSED=false
    fi

    echo ""
}

# Function to run UI tests
run_ui_tests() {
    echo -e "${YELLOW}Running UI Tests...${NC}"
    echo ""

    cd "$IOS_PROJECT"

    if $VERBOSE; then
        xcodebuild test \
            -scheme PowderTracker \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
            -only-testing:PowderTrackerUITests/EventSocialFeaturesUITests \
            2>&1
    else
        xcodebuild test \
            -scheme PowderTracker \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
            -only-testing:PowderTrackerUITests/EventSocialFeaturesUITests \
            -quiet 2>&1 | tail -30
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ UI tests passed${NC}"
        UI_TESTS_PASSED=true
    else
        echo -e "${RED}✗ UI tests failed${NC}"
        UI_TESTS_PASSED=false
    fi

    echo ""
}

# Function to run quick API smoke tests
run_api_smoke_tests() {
    echo -e "${YELLOW}Running API Smoke Tests...${NC}"
    echo ""

    # Test comments endpoint
    echo -n "  Comments endpoint... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/api/events/test/comments")
    if [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "404" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ (got $RESPONSE)${NC}"
    fi

    # Test activity endpoint
    echo -n "  Activity endpoint... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/api/events/test/activity")
    if [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "404" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ (got $RESPONSE)${NC}"
    fi

    # Test photos endpoint
    echo -n "  Photos endpoint... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/api/events/test/photos")
    if [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "404" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ (got $RESPONSE)${NC}"
    fi

    echo ""
}

# Run selected tests
if $RUN_UNIT; then
    run_unit_tests
fi

if $RUN_API; then
    run_api_smoke_tests
    run_api_tests
fi

if $RUN_UI; then
    run_ui_tests
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if $RUN_UNIT; then
    if $UNIT_TESTS_PASSED; then
        echo -e "  Unit Tests:  ${GREEN}PASSED${NC}"
    else
        echo -e "  Unit Tests:  ${RED}FAILED${NC}"
    fi
fi

if $RUN_API; then
    if $API_TESTS_PASSED; then
        echo -e "  API Tests:   ${GREEN}PASSED${NC}"
    else
        echo -e "  API Tests:   ${RED}FAILED${NC}"
    fi
fi

if $RUN_UI; then
    if $UI_TESTS_PASSED; then
        echo -e "  UI Tests:    ${GREEN}PASSED${NC}"
    else
        echo -e "  UI Tests:    ${RED}FAILED${NC}"
    fi
fi

echo ""

# Exit with error if any tests failed
if $RUN_UNIT && ! $UNIT_TESTS_PASSED; then
    exit 1
fi

if $RUN_API && ! $API_TESTS_PASSED; then
    exit 1
fi

if $RUN_UI && ! $UI_TESTS_PASSED; then
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
exit 0
