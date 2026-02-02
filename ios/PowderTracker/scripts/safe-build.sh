#!/bin/bash
#
# safe-build.sh - Prevents concurrent xcodebuild operations
#
# Usage:
#   ./scripts/safe-build.sh build          # Build the app
#   ./scripts/safe-build.sh test           # Run all tests
#   ./scripts/safe-build.sh test-ui        # Run UI tests only
#   ./scripts/safe-build.sh test-unit      # Run unit tests only
#   ./scripts/safe-build.sh clean          # Clean build artifacts
#   ./scripts/safe-build.sh status         # Check if build is running
#
# This script ensures only one xcodebuild process runs at a time,
# preventing DerivedData corruption and git lock conflicts.

set -e

LOCK_FILE="/tmp/powdertracker-build.lock"
LOCK_TIMEOUT=600  # 10 minutes max wait
SCHEME="PowderTracker"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if another xcodebuild is running (not just our lock)
check_xcodebuild_running() {
    pgrep -x xcodebuild > /dev/null 2>&1
}

# Get info about running xcodebuild
get_xcodebuild_info() {
    ps aux | grep -E "xcodebuild.*(build|test)" | grep -v grep | head -1
}

# Acquire lock with timeout
acquire_lock() {
    local waited=0
    local wait_interval=5

    while [ -f "$LOCK_FILE" ] || check_xcodebuild_running; do
        if [ $waited -eq 0 ]; then
            log_warn "Another build is in progress..."
            if [ -f "$LOCK_FILE" ]; then
                local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
                local lock_age=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))
                log_warn "Lock held by PID $lock_pid (age: ${lock_age}s)"
            fi
            if check_xcodebuild_running; then
                log_warn "Running: $(get_xcodebuild_info)"
            fi
        fi

        # Check for stale lock (older than LOCK_TIMEOUT)
        if [ -f "$LOCK_FILE" ]; then
            local lock_age=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))
            if [ $lock_age -gt $LOCK_TIMEOUT ]; then
                log_warn "Stale lock detected (${lock_age}s old), removing..."
                rm -f "$LOCK_FILE"
                continue
            fi
        fi

        # Check if lock holder is still alive
        if [ -f "$LOCK_FILE" ]; then
            local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
            if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
                log_warn "Lock holder (PID $lock_pid) is dead, removing stale lock..."
                rm -f "$LOCK_FILE"
                continue
            fi
        fi

        waited=$((waited + wait_interval))
        if [ $waited -ge $LOCK_TIMEOUT ]; then
            log_error "Timeout waiting for lock after ${waited}s"
            exit 1
        fi

        echo -n "."
        sleep $wait_interval
    done

    if [ $waited -gt 0 ]; then
        echo ""
        log_info "Lock acquired after ${waited}s"
    fi

    # Create lock file with our PID
    echo $$ > "$LOCK_FILE"
    trap cleanup EXIT INT TERM
}

# Release lock
cleanup() {
    if [ -f "$LOCK_FILE" ] && [ "$(cat "$LOCK_FILE" 2>/dev/null)" = "$$" ]; then
        rm -f "$LOCK_FILE"
        log_info "Lock released"
    fi
}

# Kill any orphaned xcodebuild processes
kill_orphans() {
    if check_xcodebuild_running; then
        log_warn "Killing orphaned xcodebuild processes..."
        killall xcodebuild 2>/dev/null || true
        sleep 2
    fi
}

# Clean up corrupted state
clean_state() {
    log_info "Cleaning build state..."

    # Remove git lock files in package caches
    find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
    find ~/Library/Developer/Xcode/DerivedData -name "index.lock" -delete 2>/dev/null || true

    # Remove corrupted build database if exists
    local db_file=~/Library/Developer/Xcode/DerivedData/PowderTracker-*/Build/Intermediates.noindex/XCBuildData/build.db
    if [ -f "$db_file" ]; then
        rm -f "$db_file"* 2>/dev/null || true
    fi

    log_info "Build state cleaned"
}

# Main commands
cmd_build() {
    acquire_lock
    clean_state
    log_info "Starting build..."
    xcodebuild build \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        2>&1 | grep -E "(error:|warning:|BUILD|Compiling)" || true
    log_info "Build complete"
}

cmd_test() {
    acquire_lock
    clean_state
    log_info "Running all tests..."
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        2>&1 | grep -E "(Test.*started|passed|failed|error:|Executed|BUILD)" || true
    log_info "Tests complete"
}

cmd_test_ui() {
    acquire_lock
    clean_state
    log_info "Running UI tests..."
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:PowderTrackerUITests \
        2>&1 | grep -E "(Test.*started|passed|failed|error:|Executed|BUILD)" || true
    log_info "UI tests complete"
}

cmd_test_unit() {
    acquire_lock
    clean_state
    log_info "Running unit tests..."
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:PowderTrackerTests \
        2>&1 | grep -E "(Test.*started|passed|failed|error:|Executed|BUILD)" || true
    log_info "Unit tests complete"
}

cmd_clean() {
    acquire_lock
    kill_orphans
    clean_state
    log_info "Cleaning DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/PowderTracker-* 2>/dev/null || true
    log_info "Clean complete"
}

cmd_status() {
    echo "=== Build Status ==="

    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        local lock_age=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))
        echo -e "${YELLOW}Lock file exists${NC}"
        echo "  PID: $lock_pid"
        echo "  Age: ${lock_age}s"
        if kill -0 "$lock_pid" 2>/dev/null; then
            echo "  Status: Process is alive"
        else
            echo "  Status: Process is dead (stale lock)"
        fi
    else
        echo -e "${GREEN}No lock file${NC}"
    fi

    echo ""
    if check_xcodebuild_running; then
        echo -e "${YELLOW}xcodebuild is running:${NC}"
        get_xcodebuild_info
    else
        echo -e "${GREEN}No xcodebuild processes running${NC}"
    fi
}

cmd_force_unlock() {
    log_warn "Force removing lock..."
    rm -f "$LOCK_FILE"
    kill_orphans
    clean_state
    log_info "Force unlock complete"
}

# Show usage
usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build        Build the app"
    echo "  test         Run all tests"
    echo "  test-ui      Run UI tests only"
    echo "  test-unit    Run unit tests only"
    echo "  clean        Clean build artifacts and DerivedData"
    echo "  status       Check build status"
    echo "  force-unlock Force remove lock and kill processes"
    echo ""
    echo "This script prevents concurrent builds to avoid DerivedData corruption."
}

# Main
cd "$(dirname "$0")/.."

case "${1:-}" in
    build)      cmd_build ;;
    test)       cmd_test ;;
    test-ui)    cmd_test_ui ;;
    test-unit)  cmd_test_unit ;;
    clean)      cmd_clean ;;
    status)     cmd_status ;;
    force-unlock) cmd_force_unlock ;;
    *)          usage ;;
esac
