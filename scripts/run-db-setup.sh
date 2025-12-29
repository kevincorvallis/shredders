#!/bin/bash

# Run database schema setup
# This script connects to the database and runs the schema SQL

set -e

echo "🏔️ Setting up database schema..."

# Load environment variables
if [ -f .env.local ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
fi

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set. Run setup-aws-database.sh first."
    exit 1
fi

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo "❌ psql not found. Install PostgreSQL client:"
    echo "   macOS: brew install postgresql"
    echo "   Ubuntu: sudo apt-get install postgresql-client"
    exit 1
fi

echo "✅ Running schema setup..."

# Run the schema SQL
psql "$DATABASE_URL" -f scripts/setup-db-schema.sql

echo ""
echo "✅ Database schema created successfully!"
echo ""
echo "Next steps:"
echo "  1. Test the scraper: npm run scraper:test"
echo "  2. Check database: psql \$DATABASE_URL"
echo "  3. Deploy to Vercel: vercel --prod"
