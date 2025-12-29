#!/bin/bash
set -e

# Get DATABASE_URL from .env.local
DATABASE_URL=$(grep DATABASE_URL .env.local | cut -d'=' -f2-)

echo "🗄️ Creating database schema..."

# Run schema creation
/opt/homebrew/opt/postgresql@15/bin/psql "$DATABASE_URL" -f scripts/setup-db-schema.sql

echo "✅ Database schema created successfully!"
