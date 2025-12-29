#!/bin/bash
set -e

echo "🚀 Adding DATABASE_URL to Vercel..."

# Get DATABASE_URL
DATABASE_URL=$(grep DATABASE_URL .env.local | cut -d'=' -f2-)

# Add to Vercel production
echo "$DATABASE_URL" | vercel env add DATABASE_URL production

echo "✅ DATABASE_URL added to Vercel production!"
