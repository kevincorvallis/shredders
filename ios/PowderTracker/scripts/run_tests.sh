#!/bin/bash
# Test Runner Script for PowderTracker iOS App
# Runs snapshot tests, performance tests, or all tests

set -e

# Configuration
PROJECT_DIR="/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker"
SCHEME="PowderTracker"
SIMULATOR_NAME="iPhone 16 Pro"
SIMULATOR_OS="18.6"

# Use unique results directory per run to avoid conflicts with parallel Claude instances
RUN_ID="$$_$(date +%s)"
RESULTS_DIR="/tmp/powdertracker_test_results_${RUN_ID}"
DERIVED_DATA_DIR="/tmp/powdertracker_derived_data_${RUN_ID}"
LOCK_FILE="/tmp/powdertracker_test.lock"

# Cleanup function
cleanup() {
    # Remove lock if we hold it
    if [ -f "$LOCK_FILE" ] && [ "$(cat "$LOCK_FILE" 2>/dev/null)" = "$$" ]; then
        rm -f "$LOCK_FILE"
    fi
    # Clean up derived data (can be large)
    rm -rf "$DERIVED_DATA_DIR" 2>/dev/null || true
}
trap cleanup EXIT

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
    echo "Usage: $0 [test_type] [options]"
    echo ""
    echo "Test types:"
    echo "  all         - Run all tests (default)"
    echo "  unit        - Run only unit tests (excludes snapshots, performance, UI)"
    echo "  ui          - Run only UI tests"
    echo "  snapshots   - Run only snapshot tests"
    echo "  performance - Run only performance tests"
    echo ""
    echo "Options:"
    echo "  record      - Record new snapshot reference images (use with 'snapshots')"
    echo ""
    echo "Environment variables for UI tests:"
    echo "  UI_TEST_EMAIL    - Test account email (default: testuser@example.com)"
    echo "  UI_TEST_PASSWORD - Test account password (default: TestPassword123!)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 unit               # Run unit tests"
    echo "  $0 ui                 # Run UI tests"
    echo "  $0 snapshots          # Run snapshot tests"
    echo "  $0 snapshots record   # Record new snapshot references"
    echo "  $0 performance        # Run performance tests"
    echo ""
    echo "  # Run UI tests with custom credentials:"
    echo "  UI_TEST_EMAIL=me@test.com UI_TEST_PASSWORD=secret $0 ui"
}

# Acquire lock with timeout (prevents multiple instances from conflicting)
acquire_lock() {
    local timeout=300  # 5 minute timeout
    local waited=0

    while [ $waited -lt $timeout ]; do
        if (set -C; echo "$$" > "$LOCK_FILE") 2>/dev/null; then
            return 0
        fi

        # Check if lock holder is still running
        local holder=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
            # Lock holder is dead, steal the lock
            rm -f "$LOCK_FILE"
            continue
        fi

        echo -e "${YELLOW}⏳ Waiting for another test run to finish (PID: $holder)...${NC}"
        sleep 5
        waited=$((waited + 5))
    done

    echo -e "${RED}❌ Timeout waiting for lock after ${timeout}s${NC}"
    return 1
}

release_lock() {
    if [ -f "$LOCK_FILE" ] && [ "$(cat "$LOCK_FILE" 2>/dev/null)" = "$$" ]; then
        rm -f "$LOCK_FILE"
    fi
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
        xcrun simctl boot "$sim_id" 2>/dev/null || true  # May already be booting
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
        -destination 'platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS' \
        -derivedDataPath '$DERIVED_DATA_DIR' \
        -resultBundlePath '$result_path'"

    if [ -n "$test_filter" ]; then
        cmd="$cmd -only-testing:$test_filter"
    fi

    eval "$cmd" 2>&1
}

echo -e "${YELLOW}🏔️  PowderTracker Test Runner${NC}"
echo "================================"
echo -e "${BLUE}Run ID: ${RUN_ID}${NC}"

cd "$PROJECT_DIR"

# Acquire lock to prevent concurrent test runs from conflicting
echo -e "${YELLOW}Acquiring test lock...${NC}"
if ! acquire_lock; then
    echo -e "${RED}❌ Could not acquire lock. Another test may be stuck.${NC}"
    echo "Remove $LOCK_FILE manually if no other tests are running."
    exit 1
fi
echo -e "${GREEN}✓ Lock acquired${NC}"

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
        # Exclude Snapshots, Performance, and UI tests
        if xcodebuild test \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS" \
            -derivedDataPath "$DERIVED_DATA_DIR" \
            -resultBundlePath "$RESULT_PATH" \
            -skip-testing:PowderTrackerTests/Snapshots \
            -skip-testing:PowderTrackerTests/Performance \
            -skip-testing:PowderTrackerUITests 2>&1; then
            echo -e "\n${GREEN}✓ Unit tests passed${NC}"
        else
            echo -e "\n${RED}❌ Unit tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            exit 1
        fi
        ;;

    "ui")
        echo -e "\n${BLUE}Running UI Tests${NC}"

        # Check for test credentials
        if [ -n "$UI_TEST_EMAIL" ]; then
            echo -e "${GREEN}✓ Using custom test email: $UI_TEST_EMAIL${NC}"
        else
            echo -e "${YELLOW}⚠️  Using default test email (set UI_TEST_EMAIL for custom)${NC}"
        fi

        SIM_ID=$(get_or_boot_simulator)
        echo -e "${GREEN}✓ Simulator ready: $SIM_ID${NC}"

        RESULT_PATH="$RESULTS_DIR/UITestResults.xcresult"
        rm -rf "$RESULT_PATH"

        echo -e "\n${YELLOW}Building and running UI tests...${NC}"
        echo -e "${YELLOW}Note: UI tests require the app to launch. This may take a while.${NC}"

        # Run UI tests with environment variables for credentials
        if xcodebuild test \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS" \
            -derivedDataPath "$DERIVED_DATA_DIR" \
            -resultBundlePath "$RESULT_PATH" \
            -only-testing:PowderTrackerUITests \
            UI_TEST_EMAIL="${UI_TEST_EMAIL:-}" \
            UI_TEST_PASSWORD="${UI_TEST_PASSWORD:-}" 2>&1; then
            echo -e "\n${GREEN}✓ UI tests passed${NC}"
        else
            echo -e "\n${RED}❌ UI tests failed${NC}"
            echo "Results saved to: $RESULT_PATH"
            echo ""
            echo -e "${YELLOW}Tip: Open the .xcresult file in Xcode to see screenshots and failure details:${NC}"
            echo "  open '$RESULT_PATH'"
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

# Release lock before final output
release_lock

echo -e "\n================================"
echo -e "${GREEN}🎉 Test run complete!${NC}"
echo "Results saved to: $RESULTS_DIR"
echo -e "${YELLOW}Note: Results directory is unique to this run and can be cleaned up.${NC}"
