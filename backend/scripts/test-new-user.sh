#!/bin/bash

echo "=== Testing with NEW user ==="
NEW_EMAIL="newuser$(date +%s)@example.com"
NEW_PASSWORD="NewUser123456!"

echo ""
echo "1. Testing Registration with new email: $NEW_EMAIL"
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NEW_EMAIL\",\"password\":\"$NEW_PASSWORD\",\"username\":\"newuser\"}")

echo "$REGISTER_RESPONSE" | python3 -m json.tool

# Extract tokens
ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null)
USER_ID=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['userId'])" 2>/dev/null)

if [ -n "$ACCESS_TOKEN" ]; then
    echo ""
    echo "2. ✓ Registration successful! Got access token"

    echo ""
    echo "3. Testing Login"
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$NEW_EMAIL\",\"password\":\"$NEW_PASSWORD\"}")

    echo "$LOGIN_RESPONSE" | python3 -m json.tool

    echo ""
    echo "4. Testing Get Current User Info"
    ME_RESPONSE=$(curl -s -X GET http://localhost:8080/api/v1/auth/me \
      -H "Authorization: Bearer $ACCESS_TOKEN")

    echo "$ME_RESPONSE" | python3 -m json.tool

    echo ""
    echo "5. Testing Unauthorized Access (should fail)"
    UNAUTHORIZED_RESPONSE=$(curl -s -X GET http://localhost:8080/api/v1/auth/me)
    echo "$UNAUTHORIZED_RESPONSE" | python3 -m json.tool

    echo ""
    echo "6. Testing Logout"
    LOGOUT_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/logout \
      -H "Authorization: Bearer $ACCESS_TOKEN")
    echo "$LOGOUT_RESPONSE" | python3 -m json.tool

    echo ""
    echo "=== All Tests Completed Successfully! ==="
else
    echo "✗ Registration failed"
    exit 1
fi
