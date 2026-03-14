#!/bin/bash

# Database Setup Script for Reader App
# This script helps you set up MySQL database for testing

set -e

echo "================================================"
echo "Reader App Database Setup"
echo "================================================"
echo ""

# Check if MySQL is running
if ! command -v mysql &> /dev/null; then
    echo "❌ Error: MySQL is not installed"
    echo "Please install MySQL 8.0+ first"
    exit 1
fi

echo "✓ MySQL is installed"
echo ""

# Prompt for MySQL root password
echo "Enter MySQL root password (leave empty if no password):"
read -s MYSQL_ROOT_PASSWORD
echo ""

# Test MySQL connection
echo "Testing MySQL connection..."
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_CMD="mysql -u root"
else
    MYSQL_CMD="mysql -u root -p${MYSQL_ROOT_PASSWORD}"
fi

if ! $MYSQL_CMD -e "SELECT 1" &> /dev/null; then
    echo "❌ Error: Cannot connect to MySQL"
    echo "Please check your password and ensure MySQL is running"
    exit 1
fi

echo "✓ MySQL connection successful"
echo ""

# Database configuration
DB_NAME="readerapp"
DB_USER="readerapp"
DB_PASSWORD="ReaderApp123!"

echo "Creating database and user..."
echo ""

# Create database
echo "1. Creating database '${DB_NAME}'..."
$MYSQL_CMD <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL

echo "✓ Database created"
echo ""

# Create user (if not exists)
echo "2. Creating database user '${DB_USER}'..."
$MYSQL_CMD <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
SQL

echo "✓ User created"
echo ""

# Grant privileges
echo "3. Granting privileges..."
$MYSQL_CMD <<SQL
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

echo "✓ Privileges granted"
echo ""

# Test new user connection
echo "4. Testing new user connection..."
if mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -e "SELECT 1" &> /dev/null; then
    echo "✓ User connection successful"
else
    echo "❌ Error: User connection failed"
    exit 1
fi

echo ""
echo "================================================"
echo "✓ Database Setup Complete!"
echo "================================================"
echo ""
echo "Database Details:"
echo "  Database Name: ${DB_NAME}"
echo "  Username: ${DB_USER}"
echo "  Password: ${DB_PASSWORD}"
echo ""
echo "Next Steps:"
echo "  1. Update backend/.env file with:"
echo "     DB_PASSWORD=${DB_PASSWORD}"
echo ""
echo "  2. Or update application.yml datasource:"
echo "     url: jdbc:mysql://localhost:3306/${DB_NAME}"
echo "     username: ${DB_USER}"
echo "     password: ${DB_PASSWORD}"
echo ""
echo "  3. Run the application:"
echo "     mvn spring-boot:run"
echo ""
echo "The Flyway migrations will run automatically on startup."
echo ""
