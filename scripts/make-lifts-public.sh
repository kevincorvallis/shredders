#!/bin/bash
#
# Make ski lift GeoJSON files publicly readable
#

BUCKET="shredders-lambda-deployments"

echo "🔓 Making lift data publicly readable..."

# Create bucket policy to allow public read for ski-data/lifts/*
cat > /tmp/lift-bucket-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadSkiLiftData",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::shredders-lambda-deployments/ski-data/lifts/*"
    }
  ]
}
EOF

# Note: This will replace the entire bucket policy
# If there are existing policies, they need to be merged
echo "⚠️  This will update the bucket policy for $BUCKET"
echo "Checking current policy..."

aws s3api get-bucket-policy --bucket "$BUCKET" 2>/dev/null || echo "No existing policy"

echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi

# Apply bucket policy (note: this requires appropriate IAM permissions)
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file:///tmp/lift-bucket-policy.json

if [ $? -eq 0 ]; then
    echo "✅ Bucket policy updated!"
    echo ""
    echo "Testing public access..."
    curl -I "https://$BUCKET.s3.us-west-2.amazonaws.com/ski-data/lifts/crystal.geojson"
else
    echo "❌ Failed to update bucket policy"
    echo "You may need additional IAM permissions or the bucket may have restrictions"
fi

rm /tmp/lift-bucket-policy.json
