#!/bin/bash

# AWS RDS PostgreSQL Setup Script for Mountain Scraper
# This script creates an RDS instance for storing scraped mountain data

set -e  # Exit on error

echo "🏔️ Setting up AWS RDS PostgreSQL for Mountain Scraper"
echo ""

# Configuration
DB_INSTANCE_IDENTIFIER="shredders-mountain-data"
DB_NAME="mountains"
DB_USERNAME="shredders_admin"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32)}"  # Generate random password if not set
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"  # Free tier eligible
ALLOCATED_STORAGE="${ALLOCATED_STORAGE:-20}"  # GB (free tier: 20GB)
AWS_REGION="${AWS_REGION:-us-west-2}"  # Oregon - close to PNW mountains
VPC_SECURITY_GROUP_ID="${VPC_SECURITY_GROUP_ID:-}"

echo "Configuration:"
echo "  Instance ID: $DB_INSTANCE_IDENTIFIER"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USERNAME"
echo "  Region: $AWS_REGION"
echo "  Instance Class: $DB_INSTANCE_CLASS"
echo ""

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install with: brew install awscli"
    exit 1
fi

# Check AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured"
echo ""

# Create RDS instance
echo "📦 Creating RDS PostgreSQL instance (this takes 5-10 minutes)..."

aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine postgres \
    --engine-version 15.4 \
    --master-username "$DB_USERNAME" \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage "$ALLOCATED_STORAGE" \
    --db-name "$DB_NAME" \
    --backup-retention-period 7 \
    --storage-encrypted \
    --publicly-accessible \
    --region "$AWS_REGION" \
    --tags Key=Project,Value=Shredders Key=Environment,Value=Production \
    2>&1 || {
        echo "⚠️  Instance might already exist. Checking status..."
    }

# Wait for instance to be available
echo "⏳ Waiting for database to be available..."
aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --region "$AWS_REGION"

echo "✅ Database instance created and available"
echo ""

# Get connection details
echo "📋 Fetching connection details..."

ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --region "$AWS_REGION" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

PORT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --region "$AWS_REGION" \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

# Save credentials to .env.local
echo ""
echo "💾 Saving connection string to .env.local..."

cat >> /Users/kevin/Downloads/shredders/.env.local << EOF

# AWS RDS PostgreSQL Connection (Added by setup-aws-database.sh)
DATABASE_URL=postgresql://${DB_USERNAME}:${DB_PASSWORD}@${ENDPOINT}:${PORT}/${DB_NAME}?sslmode=require
DB_HOST=${ENDPOINT}
DB_PORT=${PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
EOF

echo "✅ Connection details saved to .env.local"
echo ""

# Print connection info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Database Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Connection Details:"
echo "  Host: $ENDPOINT"
echo "  Port: $PORT"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USERNAME"
echo "  Password: $DB_PASSWORD"
echo ""
echo "Connection String:"
echo "  postgresql://${DB_USERNAME}:${DB_PASSWORD}@${ENDPOINT}:${PORT}/${DB_NAME}?sslmode=require"
echo ""
echo "⚠️  IMPORTANT: Add these to your Vercel environment variables:"
echo "  vercel env add DATABASE_URL production"
echo "  (paste the connection string above)"
echo ""
echo "Next Steps:"
echo "  1. Run the schema setup: npm run db:setup"
echo "  2. Test the scraper: curl http://localhost:3000/api/scraper/run"
echo "  3. Deploy to Vercel: vercel --prod"
echo ""
echo "💰 Cost Estimate (Free Tier):"
echo "  - db.t3.micro: FREE for first 750 hours/month"
echo "  - 20GB storage: FREE"
echo "  - Estimated: \$0/month (within free tier limits)"
echo ""
echo "🔐 Security:"
echo "  - Keep .env.local in .gitignore"
echo "  - Use AWS Security Groups to restrict access"
echo "  - Rotate password regularly"
echo ""
