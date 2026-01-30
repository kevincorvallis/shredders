#!/bin/bash
# Test Runner Script for PowderTracker iOS App
# Runs snapshot tests, performance tests, or all tests

set -e

# Configuration
PROJECT_DIR="/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker"
SCHEME="PowderTracker"
SIMULATOR_NAME="iPhone 15 Pro"
RESULTS_DIR="/tmp/powdertracker_test_results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "$RESULTS_DIR"

# Parse arguments
TEST_TYPE="${1:-all}"
RECORD_SNAPSHOTS="${2:-false}"

usage() {
    echo "Usage: $0 [test_type] [record_snapshots]"
    echo ""
    echo "Test types:"
    echo "  all         - Run all tests (default)"
    echo "  snapshots   - Run only snapshot tests"
    echo "  performance - Run only performance tests"
    echo "  unit        - Run only unit tests"
    echo ""
    echo "Options:"
    echo "  record      - Record new snapshot reference images (use with 'snapshots')"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 snapshots          # Run snapshot tests"
    echo "  $0 snapshots record   # Record new snapshot references"
    echo "  $0 performance        # Run performance tests"
}

# Function to get or boot simulator
get_or_boot_simulator() {
    local sim_id=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -oE '[A-F0-9-]{36}' | head -1)

    if [ -z "$sim_id" ]; then
        echo -e "${RED}❌ Simulator '$SIMULATOR_NAME' not found${NC}"
        exit 1
    fi

    local status=$(xcrun simctl list devices | grep "$sim_id" | grep -o "(Booted)" || true)

    if [ -z "$status" ]; then
        echo -e "${YELLOW}Booting simulator...${NC}"
        xcrun simctl boot "$sim_id"
        sleep 5
    fi

    echo "$sim_id"
}

# Function to run xcodebuild tests
run_tests() {
    local test_filter="$1"
    local result_path="$2"

    local cmd="xcodebuild test \
        -scheme $SCHEME \
        -destination 'platform=iOS Simulator,name=$SIMULATOR_NAME' \
        -resultBundlePath '$result_path'"

    if [ -n "$test_filter" ]; then
        cmd="$cmd -only-testing:$test_filter"
    fi

    eval "$cmd" 2>&1
}

echo -e "${YELLOW}🏔️  PowderTracker Test Runner${NC}"
echo "================================"

cd "$PROJECT_DIR"

case "$TEST_TYPE" in
    "snapshots")
        echo -e "\n${BLUE}Running Snapshot Tests${NC}"

        if [ "$RECORD_SNAPSHOTS" = "record" ]; then
            echo -e "${YELLOW}⚠️  Recording new reference images${NC}"
            echo "Make sure to set isRecording = true in SnapshotTestConfig.swift"
        fi

        SIM_ID=$(get_or_boot_simulator)
        echo -e "${GREEN}✓ Simulator ready: $SIM_ID${NC}"

        RESULT_PATH="$RESULTS_DIR/SnapshotResults.xcresult"
        rm -rf "$RESULT_PATH"

        echo -e "\n${YELLOW}Building and running snapshot tests...${NC}"
        if run_tests "PowderTrackerTests/Snapshots" "$RESULT_PATH"; then
            echo -e "\n${GREEN}✓ Snapshot tests passed${NC}"
        else
            echo -e "\n${RED}❌ Snapshot tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            exit 1
        fi
        ;;

    "performance")
        echo -e "\n${BLUE}Running Performance Tests${NC}"

        SIM_ID=$(get_or_boot_simulator)
        echo -e "${GREEN}✓ Simulator ready: $SIM_ID${NC}"

        RESULT_PATH="$RESULTS_DIR/PerformanceResults.xcresult"
        rm -rf "$RESULT_PATH"

        echo -e "\n${YELLOW}Building and running performance tests...${NC}"
        if run_tests "PowderTrackerTests/Performance" "$RESULT_PATH"; then
            echo -e "\n${GREEN}✓ Performance tests passed${NC}"
        else
            echo -e "\n${RED}❌ Performance tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            exit 1
        fi

        # Extract performance results
        echo -e "\n${YELLOW}Performance Results:${NC}"
        xcrun xcresulttool get --path "$RESULT_PATH" --format json 2>/dev/null | \
            grep -A 5 "averageMeasuredValue" || echo "Run 'xcrun xcresulttool get --path $RESULT_PATH' for detailed results"
        ;;

    "unit")
        echo -e "\n${BLUE}Running Unit Tests${NC}"

        SIM_ID=$(get_or_boot_simulator)
        echo -e "${GREEN}✓ Simulator ready: $SIM_ID${NC}"

        RESULT_PATH="$RESULTS_DIR/UnitResults.xcresult"
        rm -rf "$RESULT_PATH"

        echo -e "\n${YELLOW}Building and running unit tests...${NC}"
        # Exclude Snapshots and Performance directories
        if xcodebuild test \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
            -resultBundlePath "$RESULT_PATH" \
            -skip-testing:PowderTrackerTests/Snapshots \
            -skip-testing:PowderTrackerTests/Performance 2>&1; then
            echo -e "\n${GREEN}✓ Unit tests passed${NC}"
        else
            echo -e "\n${RED}❌ Unit tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            exit 1
        fi
        ;;

    "all")
        echo -e "\n${BLUE}Running All Tests${NC}"

        SIM_ID=$(get_or_boot_simulator)
        echo -e "${GREEN}✓ Simulator ready: $SIM_ID${NC}"

        RESULT_PATH="$RESULTS_DIR/AllResults.xcresult"
        rm -rf "$RESULT_PATH"

        echo -e "\n${YELLOW}Building and running all tests...${NC}"
        if run_tests "" "$RESULT_PATH"; then
            echo -e "\n${GREEN}✓ All tests passed${NC}"
        else
            echo -e "\n${RED}❌ Some tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            exit 1
        fi
        ;;

    "help"|"-h"|"--help")
        usage
        exit 0
        ;;

    *)
        echo -e "${RED}Unknown test type: $TEST_TYPE${NC}"
        usage
        exit 1
        ;;
esac

echo -e "\n================================"
echo -e "${GREEN}🎉 Test run complete!${NC}"
echo "Results saved to: $RESULTS_DIR"
