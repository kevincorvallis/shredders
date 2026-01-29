#!/bin/bash

# Production Verification Script
# Run this after deploying changes to verify the backend is working correctly

set -e

API_BASE="https://shredders-bay.vercel.app/api"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "  Production Verification Script"
echo "  $(date)"
echo "======================================"
echo ""

# Function to check endpoint
check_endpoint() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local expected_status="$4"
    local auth_header="$5"

    if [ -n "$auth_header" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: $auth_header" \
            -d '{"mountainId":"stevens","title":"Test","eventDate":"2026-02-15"}' 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -d '{"mountainId":"stevens","title":"Test","eventDate":"2026-02-15"}' 2>/dev/null)
    fi

    status=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$status" == "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} $name (HTTP $status)"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name - Expected $expected_status, got $status"
        echo "  Response: $(echo "$body" | head -c 100)"
        ((FAIL++))
        return 1
    fi
}

# Function to check JSON response
check_json_endpoint() {
    local name="$1"
    local endpoint="$2"
    local json_key="$3"

    response=$(curl -s "$API_BASE$endpoint" 2>/dev/null)

    if echo "$response" | jq -e ".$json_key" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name (valid JSON with '$json_key')"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name - Missing '$json_key' in response"
        echo "  Response: $(echo "$response" | head -c 100)"
        ((FAIL++))
        return 1
    fi
}

echo "1. Checking API Availability..."
echo "--------------------------------"

# Basic connectivity
if curl -s --connect-timeout 5 "$API_BASE/events" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} API is reachable"
    ((PASS++))
else
    echo -e "${RED}✗${NC} API is not reachable!"
    ((FAIL++))
    echo "Aborting further tests."
    exit 1
fi

echo ""
echo "2. Checking Public Endpoints..."
echo "--------------------------------"

check_json_endpoint "GET /events" "/events" "events"
check_json_endpoint "GET /events (pagination)" "/events" "pagination"
check_json_endpoint "GET /mountains" "/mountains" "mountains"

# Check a specific mountain
check_json_endpoint "GET /mountains/stevens" "/mountains/stevens" "id"

echo ""
echo "3. Checking Auth Protection..."
echo "--------------------------------"

check_endpoint "POST /events (no auth)" "POST" "/events" "401"
check_endpoint "POST /events/test/rsvp (no auth)" "POST" "/events/test-id/rsvp" "401"

echo ""
echo "4. Checking Auth Endpoints..."
echo "--------------------------------"

# Test signup validation
signup_response=$(curl -s -X POST "$API_BASE/auth/signup" \
    -H "Content-Type: application/json" \
    -d '{"email":"invalid","password":"weak"}' 2>/dev/null)

if echo "$signup_response" | grep -q "error\|details"; then
    echo -e "${GREEN}✓${NC} POST /auth/signup validates input"
    ((PASS++))
else
    echo -e "${RED}✗${NC} POST /auth/signup validation not working"
    ((FAIL++))
fi

# Test login endpoint exists
login_response=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}' 2>/dev/null)

if echo "$login_response" | grep -q "error\|Invalid"; then
    echo -e "${GREEN}✓${NC} POST /auth/login responds correctly"
    ((PASS++))
else
    echo -e "${YELLOW}?${NC} POST /auth/login - unexpected response"
fi

echo ""
echo "5. Checking Data Quality..."
echo "--------------------------------"

# Check events have required fields
events_response=$(curl -s "$API_BASE/events" 2>/dev/null)
event_count=$(echo "$events_response" | jq '.events | length' 2>/dev/null || echo "0")

if [ "$event_count" -gt 0 ]; then
    # Check first event has required fields
    has_creator=$(echo "$events_response" | jq '.events[0].creator' 2>/dev/null)
    has_mountain=$(echo "$events_response" | jq '.events[0].mountainId' 2>/dev/null)

    if [ "$has_creator" != "null" ] && [ "$has_mountain" != "null" ]; then
        echo -e "${GREEN}✓${NC} Events have creator and mountain data"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} Events missing required fields"
        ((FAIL++))
    fi
else
    echo -e "${YELLOW}?${NC} No events to verify (empty list)"
fi

# Check mountains have required fields
mountains_response=$(curl -s "$API_BASE/mountains" 2>/dev/null)
mountain_count=$(echo "$mountains_response" | jq '.mountains | length' 2>/dev/null || echo "0")

if [ "$mountain_count" -gt 20 ]; then
    echo -e "${GREEN}✓${NC} Mountains list has $mountain_count entries"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Mountains list too short: $mountain_count"
    ((FAIL++))
fi

echo ""
echo "6. Response Time Check..."
echo "--------------------------------"

# Use curl's built-in timing (works on macOS and Linux)
response_time=$(curl -s -o /dev/null -w "%{time_total}" "$API_BASE/events" 2>/dev/null)
# Convert to milliseconds without bc (awk is more portable)
response_ms=$(echo "$response_time" | awk '{printf "%.0f", $1 * 1000}')

if [ "$response_ms" -lt 1000 ]; then
    echo -e "${GREEN}✓${NC} Response time: ${response_ms}ms (< 1000ms)"
    ((PASS++))
elif [ "$response_ms" -lt 3000 ]; then
    echo -e "${YELLOW}?${NC} Response time: ${response_ms}ms (slow but acceptable)"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Response time: ${response_ms}ms (too slow!)"
    ((FAIL++))
fi

echo ""
echo "======================================"
echo "  Results"
echo "======================================"
echo ""
echo -e "  ${GREEN}Passed:${NC} $PASS"
echo -e "  ${RED}Failed:${NC} $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Production is healthy.${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. Please investigate.${NC}"
    exit 1
fi
