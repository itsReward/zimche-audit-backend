#!/bin/bash

echo "🐘 Setting up PostgreSQL for ZIMCHE Audit System..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL first."
    echo ""
    echo "On macOS: brew install postgresql"
    echo "On Ubuntu: sudo apt-get install postgresql postgresql-contrib"
    echo "On CentOS/RHEL: sudo yum install postgresql postgresql-server"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ PostgreSQL is not running. Please start PostgreSQL service."
    echo ""
    echo "On macOS: brew services start postgresql"
    echo "On Ubuntu: sudo systemctl start postgresql"
    echo "On CentOS/RHEL: sudo systemctl start postgresql"
    exit 1
fi

echo "✅ PostgreSQL is installed and running"

# Create database and user
echo "📝 Creating database and user..."

sudo -u postgres psql << EOF
-- Create user
CREATE USER zimche_user WITH PASSWORD 'zimche_password';

-- Create database
CREATE DATABASE zimche_audit_dev WITH OWNER zimche_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE zimche_audit_dev TO zimche_user;

-- Connect to the database and grant schema privileges
\c zimche_audit_dev;
GRANT ALL ON SCHEMA public TO zimche_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO zimche_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO zimche_user;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Exit
\q
