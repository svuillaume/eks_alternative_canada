#!/usr/bin/env bash

set -eux

MONGO_USER="admin"
MONGO_PASS="admin" 
MONGO_HOST="localhost"
MONGO_PORT="27017"

export AWS_ACCESS_KEY_ID="your_access_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
export AWS_SESSION_TOKEN="your_session_token_here"
S3_BUCKET="your-bucket-name"


# Create a timestamp for unique backup names
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="mongodb-backup-$DATE"

# Step 1: Create temporary backup folder
mkdir -p /tmp/$BACKUP_NAME
cd /tmp

# Step 2: Create the backup
mongodump --host $MONGO_HOST:$MONGO_PORT \
          --username $MONGO_USER \
          --password $MONGO_PASS \
          --authenticationDatabase admin \
          --out $BACKUP_NAME

# Step 3: Compress the backup
tar -czf $BACKUP_NAME.tar.gz $BACKUP_NAME/

# Step 4: Upload to S3
aws s3 cp $BACKUP_NAME.tar.gz s3://$S3_BUCKET/

# Step 5: Clean up temporary files
rm -rf $BACKUP_NAME
rm -f $BACKUP_NAME.tar.gz

echo ""
echo "🎉 Backup completed successfully!"
echo "Backup file: $BACKUP_NAME.tar.gz"
echo "Location: s3://$S3_BUCKET/$BACKUP_NAME.tar.gz"
echo ""
