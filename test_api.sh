#!/bin/bash
# API Test Script for OnePunch Time Tracking

BASE_URL="http://localhost:2030/api/v1"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "OnePunch API Test Script"
echo "========================================="
echo ""

# Check if API token is provided
if [ -z "$API_TOKEN" ]; then
  echo -e "${RED}Error: API_TOKEN environment variable not set${NC}"
  echo "Usage: API_TOKEN=your_token_here ./test_api.sh"
  echo ""
  echo "To get your API token:"
  echo "1. Run: rails console"
  echo "2. Execute: User.first.api_token"
  exit 1
fi

echo "Using API Token: ${API_TOKEN:0:10}..."
echo ""

# Test 1: Get Current User
echo -e "${YELLOW}Test 1: GET /api/v1/users/me${NC}"
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "$BASE_URL/users/me" | jq '.'
echo ""
echo ""

# Test 2: Get Projects
echo -e "${YELLOW}Test 2: GET /api/v1/projects${NC}"
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "$BASE_URL/projects" | jq '.'
echo ""
echo ""

# Test 3: Get Current Timer Status
echo -e "${YELLOW}Test 3: GET /api/v1/timer/current${NC}"
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "$BASE_URL/timer/current" | jq '.'
echo ""
echo ""

# Test 4: Get Time Entries
echo -e "${YELLOW}Test 4: GET /api/v1/time_entries${NC}"
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "$BASE_URL/time_entries" | jq '.'
echo ""
echo ""

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}API Tests Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
