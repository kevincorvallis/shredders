#!/bin/bash

# Comprehensive Pre-Deployment Check Script
# Runs all tests and verifications before deploying to production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios/PowderTracker"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0

# Timing
START_TIME=$(date +%s)

# Parse arguments
TIER="quick"
VERBOSE=false

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Tiers (mutually exclusive):"
    echo "  --quick       Quick API checks only (default, ~1 min)"
    echo "  --standard    API + iOS build + unit tests (~15 min)"
    echo "  --full        Everything including UI tests (~45 min)"
    echo "  --all         Alias for --full"
    echo ""
    echo "Options:"
    echo "  --verbose     Show detailed output"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Quick checks"
    echo "  $0 --standard       # Standard verification"
    echo "  $0 --full --verbose # Full verification with details"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            TIER="quick"
            shift
            ;;
        --standard)
            TIER="standard"
            shift
            ;;
        --full|--all)
            TIER="full"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo "──────────────────────────────────────────────"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

check_skip() {
    echo -e "${YELLOW}○${NC} $1 (skipped)"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================
# CHECKS
# ============================================

check_git_status() {
    print_section "Git Status"

    cd "$PROJECT_ROOT"

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        check_warn "Uncommitted changes detected"
        if [ "$VERBOSE" = true ]; then
            git status --short
        fi
    else
        check_pass "Working directory clean"
    fi

    # Check current branch
    BRANCH=$(git branch --show-current)
    echo -e "  Current branch: ${CYAN}$BRANCH${NC}"

    # Check if up to date with remote
    git fetch origin --quiet 2>/dev/null || true
    LOCAL=$(git rev-parse HEAD 2>/dev/null)
    REMOTE=$(git rev-parse origin/$BRANCH 2>/dev/null || echo "")

    if [ "$LOCAL" = "$REMOTE" ]; then
        check_pass "Branch is up to date with remote"
    elif [ -n "$REMOTE" ]; then
        check_warn "Branch differs from remote"
    fi
}

check_api_health() {
    print_section "Backend API Health"

    if [ -f "$IOS_DIR/scripts/verify-production.sh" ]; then
        if "$IOS_DIR/scripts/verify-production.sh"; then
            check_pass "All API checks passed"
        else
            check_fail "API checks failed"
            return 1
        fi
    else
        check_fail "verify-production.sh not found"
        return 1
    fi
}

check_ios_build() {
    print_section "iOS App Build"

    cd "$IOS_DIR"

    echo "Building iOS app (this may take a minute)..."

    if xcodebuild -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -quiet \
        build 2>&1; then
        check_pass "iOS app builds successfully"
    else
        check_fail "iOS app build failed"
        return 1
    fi
}

check_unit_tests() {
    print_section "iOS Unit Tests"

    cd "$IOS_DIR"

    echo "Running unit tests..."

    RESULTS_DIR="/tmp/deploy_check_unit_$$"
    mkdir -p "$RESULTS_DIR"

    if xcodebuild test \
        -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -resultBundlePath "$RESULTS_DIR/UnitResults.xcresult" \
        -skip-testing:PowderTrackerTests/Snapshots \
        -skip-testing:PowderTrackerTests/Performance \
        -quiet 2>&1; then
        check_pass "All unit tests passed"
        rm -rf "$RESULTS_DIR"
    else
        check_fail "Unit tests failed"
        echo "  Results: $RESULTS_DIR/UnitResults.xcresult"
        return 1
    fi
}

check_snapshot_tests() {
    print_section "iOS Snapshot Tests"

    cd "$IOS_DIR"

    echo "Running snapshot tests..."

    RESULTS_DIR="/tmp/deploy_check_snapshots_$$"
    mkdir -p "$RESULTS_DIR"

    if xcodebuild test \
        -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -resultBundlePath "$RESULTS_DIR/SnapshotResults.xcresult" \
        -only-testing:PowderTrackerTests/Snapshots \
        -quiet 2>&1; then
        check_pass "All snapshot tests passed"
        rm -rf "$RESULTS_DIR"
    else
        check_fail "Snapshot tests failed (visual regressions detected)"
        echo "  Results: $RESULTS_DIR/SnapshotResults.xcresult"
        echo "  If intentional: ./scripts/run_tests.sh snapshots record"
        return 1
    fi
}

check_ui_tests() {
    print_section "iOS UI Tests"

    cd "$IOS_DIR"

    echo "Running UI tests (this may take several minutes)..."

    RESULTS_DIR="/tmp/deploy_check_ui_$$"
    mkdir -p "$RESULTS_DIR"

    if xcodebuild test \
        -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -resultBundlePath "$RESULTS_DIR/UIResults.xcresult" \
        -only-testing:PowderTrackerUITests \
        -quiet 2>&1; then
        check_pass "All UI tests passed"
        rm -rf "$RESULTS_DIR"
    else
        check_fail "UI tests failed"
        echo "  Results: $RESULTS_DIR/UIResults.xcresult"
        return 1
    fi
}

check_performance_tests() {
    print_section "iOS Performance Tests"

    cd "$IOS_DIR"

    echo "Running performance tests..."

    RESULTS_DIR="/tmp/deploy_check_perf_$$"
    mkdir -p "$RESULTS_DIR"

    if xcodebuild test \
        -scheme PowderTracker \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -resultBundlePath "$RESULTS_DIR/PerfResults.xcresult" \
        -only-testing:PowderTrackerTests/Performance \
        -quiet 2>&1; then
        check_pass "All performance tests passed baselines"
        rm -rf "$RESULTS_DIR"
    else
        check_fail "Performance tests failed (regression detected)"
        echo "  Results: $RESULTS_DIR/PerfResults.xcresult"
        return 1
    fi
}

check_e2e() {
    print_section "E2E Visual Verification"

    cd "$IOS_DIR"

    if [ -f "scripts/e2e_test.sh" ]; then
        echo "Running E2E test with screenshots..."
        if ./scripts/e2e_test.sh; then
            check_pass "E2E test completed with screenshots"
        else
            check_fail "E2E test failed"
            return 1
        fi
    else
        check_skip "E2E test script not found"
    fi
}

print_summary() {
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    print_header "Summary"

    echo -e "  ${GREEN}Passed:${NC}  $PASSED_CHECKS"
    echo -e "  ${RED}Failed:${NC}  $FAILED_CHECKS"
    echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED_CHECKS"
    echo -e "  Total:   $TOTAL_CHECKS"
    echo ""
    echo -e "  Duration: ${DURATION}s"
    echo ""

    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ All checks passed! Safe to deploy.${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        return 0
    else
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ✗ $FAILED_CHECKS check(s) failed. Fix issues before deploying.${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        return 1
    fi
}

# ============================================
# MAIN
# ============================================

print_header "Pre-Deployment Verification (Tier: $TIER)"

echo -e "Started at: $(date)"
echo -e "Project:    $PROJECT_ROOT"

# Always run
check_git_status
check_api_health || true

# Standard tier adds build and unit tests
if [ "$TIER" = "standard" ] || [ "$TIER" = "full" ]; then
    check_ios_build || true
    check_unit_tests || true
fi

# Full tier adds snapshot, UI, and performance tests
if [ "$TIER" = "full" ]; then
    check_snapshot_tests || true
    check_ui_tests || true
    check_performance_tests || true
    check_e2e || true
fi

print_summary
exit $?
