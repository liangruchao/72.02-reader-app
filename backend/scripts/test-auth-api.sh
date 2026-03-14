#!/bin/bash

# Auth API Test Script for Reader App
# This script tests all authentication endpoints

set -e

# Configuration
API_BASE_URL="http://localhost:8080/api/v1/auth"
CONTENT_TYPE="Content-Type: application/json"

echo "================================================"
echo "Reader App Authentication API Tests"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test variables
TEST_EMAIL="test@example.com"
TEST_PASSWORD="TestPassword123!"
TEST_USERNAME="testuser"

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ Success: $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
}

# Check if server is running
echo "1. Checking if server is running..."
if ! curl -s "${API_BASE_URL}/login" > /dev/null 2>&1; then
    print_error "Server is not running at ${API_BASE_URL}"
    echo ""
    echo "Please start the server first:"
    echo "  cd backend"
    echo "  mvn spring-boot:run"
    exit 1
fi

print_success "Server is running"
echo ""

# Test 1: User Registration
print_test "User Registration"
REGISTER_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/register" \
  -H "${CONTENT_TYPE}" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\",
    \"username\": \"${TEST_USERNAME}\",
    \"displayName\": \"Test User\"
  }")

echo "Response: ${REGISTER_RESPONSE}"

if echo "${REGISTER_RESPONSE}" | grep -q '"success":true'; then
    print_success "User registered"

    # Extract tokens
    ACCESS_TOKEN=$(echo "${REGISTER_RESPONSE}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "${REGISTER_RESPONSE}" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    USER_ID=$(echo "${REGISTER_RESPONSE}" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)

    echo "Access Token: ${ACCESS_TOKEN:0:50}..."
    echo "Refresh Token: ${REFRESH_TOKEN:0:50}..."
    echo "User ID: ${USER_ID}"
else
    print_error "Registration failed"
    echo ""
    echo "Maybe user already exists? Trying to login instead..."
fi

echo ""

# Test 2: User Login (or if registration failed)
print_test "User Login"
LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/login" \
  -H "${CONTENT_TYPE}" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

echo "Response: ${LOGIN_RESPONSE}"

if echo "${LOGIN_RESPONSE}" | grep -q '"success":true'; then
    print_success "User logged in"

    # Extract tokens (in case registration failed)
    ACCESS_TOKEN=$(echo "${LOGIN_RESPONSE}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "${LOGIN_RESPONSE}" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    USER_ID=$(echo "${LOGIN_RESPONSE}" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)

    echo "Access Token: ${ACCESS_TOKEN:0:50}..."
    echo "Refresh Token: ${REFRESH_TOKEN:0:50}..."
else
    print_error "Login failed"
    exit 1
fi

echo ""

# Test 3: Get Current User Info
print_test "Get Current User Info"
ME_RESPONSE=$(curl -s -X GET "${API_BASE_URL}/me" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "Response: ${ME_RESPONSE}"

if echo "${ME_RESPONSE}" | grep -q '"success":true'; then
    print_success "User info retrieved"
else
    print_error "Failed to get user info"
fi

echo ""

# Test 4: Test Protected Endpoint without Token (should fail)
print_test "Access Protected Endpoint Without Token (should fail)"
UNAUTHORIZED_RESPONSE=$(curl -s -X GET "${API_BASE_URL}/me")

echo "Response: ${UNAUTHORIZED_RESPONSE}"

if echo "${UNAUTHORIZED_RESPONSE}" | grep -q '"success":false'; then
    print_success "Correctly rejected unauthorized request"
else
    print_error "Security issue: unauthorized request was not rejected"
fi

echo ""

# Test 5: Test Invalid Credentials
print_test "Login with Invalid Credentials (should fail)"
INVALID_LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/login" \
  -H "${CONTENT_TYPE}" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"WrongPassword\"
  }")

echo "Response: ${INVALID_LOGIN_RESPONSE}"

if echo "${INVALID_LOGIN_RESPONSE}" | grep -q '"success":false'; then
    print_success "Correctly rejected invalid credentials"
else
    print_error "Security issue: invalid credentials were not rejected"
fi

echo ""

# Test 6: Refresh Token
print_test "Refresh Token"
REFRESH_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/refresh?refreshToken=${REFRESH_TOKEN}")

echo "Response: ${REFRESH_RESPONSE}"

if echo "${REFRESH_RESPONSE}" | grep -q '"success":true'; then
    print_success "Token refreshed"

    NEW_ACCESS_TOKEN=$(echo "${REFRESH_RESPONSE}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    echo "New Access Token: ${NEW_ACCESS_TOKEN:0:50}..."
else
    print_error "Token refresh failed"
fi

echo ""

# Test 7: Logout
print_test "Logout"
LOGOUT_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/logout" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "Response: ${LOGOUT_RESPONSE}"

if echo "${LOGOUT_RESPONSE}" | grep -q '"success":true'; then
    print_success "Logout successful"
else
    print_error "Logout failed"
fi

echo ""

# Test 8: Test Validation Errors
print_test "Registration with Invalid Email (should fail)"
VALIDATION_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/register" \
  -H "${CONTENT_TYPE}" \
  -d "{
    \"email\": \"invalid-email\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

echo "Response: ${VALIDATION_RESPONSE}"

if echo "${VALIDATION_RESPONSE}" | grep -q '"success":false'; then
    print_success "Correctly rejected invalid email"
else
    print_error "Validation issue: invalid email was not rejected"
fi

echo ""

# Test 9: Test Duplicate Registration
print_test "Register Duplicate User (should fail)"
DUPLICATE_RESPONSE=$(curl -s -X POST "${API_BASE_URL}/register" \
  -H "${CONTENT_TYPE}" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\",
    \"username\": \"${TEST_USERNAME}\"
  }")

echo "Response: ${DUPLICATE_RESPONSE}"

if echo "${DUPLICATE_RESPONSE}" | grep -q '"success":false'; then
    print_success "Correctly rejected duplicate registration"
else
    print_error "Duplicate registration was not rejected"
fi

echo ""
echo "================================================"
echo "✓ All Tests Completed!"
echo "================================================"
echo ""
echo "Summary:"
echo "  • User Registration: Tested"
echo "  • User Login: Tested"
echo "  • Get Current User: Tested"
echo "  • Token Refresh: Tested"
echo "  • Logout: Tested"
echo "  • Validation: Tested"
echo "  • Security: Tested"
echo ""
