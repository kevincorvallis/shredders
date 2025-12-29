#!/bin/bash
set -e

echo "🏔️ Creating AWS RDS PostgreSQL database..."

# Read password
DB_PASSWORD=$(cat /tmp/db_password.txt)

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier shredders-mountain-data \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.15 \
    --master-username shredders_admin \
    --master-user-password "${DB_PASSWORD}" \
    --allocated-storage 20 \
    --db-name mountains \
    --backup-retention-period 7 \
    --storage-encrypted \
    --publicly-accessible \
    --region us-west-2 \
    --tags Key=Project,Value=Shredders Key=Environment,Value=Production \
    --no-cli-pager

echo "✅ Database creation initiated"
echo "⏳ Waiting for database to become available (this takes 5-10 minutes)..."

# Wait for availability
aws rds wait db-instance-available \
    --db-instance-identifier shredders-mountain-data \
    --region us-west-2

echo "✅ Database is now available!"

# Get endpoint
ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier shredders-mountain-data \
    --region us-west-2 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

PORT=$(aws rds describe-db-instances \
    --db-instance-identifier shredders-mountain-data \
    --region us-west-2 \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

# Create connection string
DATABASE_URL="postgresql://shredders_admin:${DB_PASSWORD}@${ENDPOINT}:${PORT}/mountains?sslmode=require"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Database Created Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Endpoint: ${ENDPOINT}"
echo "Port: ${PORT}"
echo "Database: mountains"
echo "Username: shredders_admin"
echo "Password: ${DB_PASSWORD}"
echo ""
echo "Connection String:"
echo "${DATABASE_URL}"
echo ""

# Save to .env.local
cat >> .env.local << EOF

# AWS RDS PostgreSQL Connection (Added on $(date))
DATABASE_URL=${DATABASE_URL}
DB_HOST=${ENDPOINT}
DB_PORT=${PORT}
DB_NAME=mountains
DB_USER=shredders_admin
DB_PASSWORD=${DB_PASSWORD}
EOF

echo "✅ Connection details saved to .env.local"
echo ""
echo "Next step: Run npm run db:setup to create schema"
