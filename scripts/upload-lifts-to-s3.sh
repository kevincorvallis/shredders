#!/bin/bash
#
# Upload ski lift GeoJSON files to S3
#

BUCKET="shredders-lambda-deployments"
S3_PREFIX="ski-data/lifts"
LOCAL_DIR="./data/ski-lifts/geojson"

echo "🚀 Uploading lift data to S3..."
echo "Bucket: s3://$BUCKET/$S3_PREFIX/"
echo ""

# Check if geojson directory exists
if [ ! -d "$LOCAL_DIR" ]; then
    echo "❌ Error: Directory $LOCAL_DIR not found"
    exit 1
fi

# Upload all GeoJSON files
for file in "$LOCAL_DIR"/*.geojson; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "📤 Uploading $filename..."
        aws s3 cp "$file" "s3://$BUCKET/$S3_PREFIX/$filename" \
            --content-type "application/geo+json" \
            --acl public-read \
            --cache-control "max-age=86400"
    fi
done

echo ""
echo "✅ Upload complete!"
echo "Files available at:"
for file in "$LOCAL_DIR"/*.geojson; do
    filename=$(basename "$file")
    echo "  https://$BUCKET.s3.us-west-2.amazonaws.com/$S3_PREFIX/$filename"
done
