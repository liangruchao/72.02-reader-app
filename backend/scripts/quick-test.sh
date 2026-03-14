#!/bin/bash

echo "Testing Registration API..."
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!","username":"testuser"}' \
  | python3 -m json.tool

echo ""
echo "Testing Login API..."
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!"}' \
  | python3 -m json.tool
