# Infrastructure Documentation

## Infrastructure Diagram

<img width="2443" height="1587" alt="Infrastructure Diagram" src="https://github.com/user-attachments/assets/f15824e6-f7fb-4e4a-b664-a9e5fe9d98dc" />

## Table of Contents

- [EKS Connection](#eks-connection)
- [Kubernetes Operations](#kubernetes-operations)
- [MongoDB Setup](#mongodb-setup)
- [MongoDB Operations](#mongodb-operations)
- [AWS Authentication](#aws-authentication)
- [MongoDB Backup & Restore](#mongodb-backup--restore)

## EKS Connection

Connect to your EKS cluster using Terraform outputs:

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)
```

## Kubernetes Operations

### Scale Web Deployment

Scale the web deployment to 5 replicas:

```bash
kubectl scale deployment web --replicas=5
```

## MongoDB Setup

### Connection String

Use the following MongoDB connection string for your applications:

```
mongoUri = 'mongodb://admin:admin@10.0.1.221:27017/gameofthrones?authSource=admin';
```

## MongoDB Operations

Connect to MongoDB and perform basic operations:

```bash
mongosh admin
db.auth("admin", "admin")
show dbs
use test
show collections  # or show tables
db.gameofthrones.find()
```

## AWS Authentication

Verify your AWS credentials and identity:

```bash
aws sts get-caller-identity
```

## MongoDB Backup & Restore

### Install Backup Script

Install the MongoDB backup script:

```bash
sudo install -m 0755 mongodb-backup.sh /usr/local/bin/mongodb-backup.sh
```

### Configure Cron Jobs

#### Manage Cron Jobs

```bash
# Edit cron jobs
sudo crontab -e

# List current cron jobs
sudo crontab -l
```

#### Backup Frequency Options

Choose from the following backup frequencies:

```bash
# Every minute (for testing)
* * * * * /usr/local/bin/backup-mongo.sh mongodb-backups-got-unique >> /var/log/mongobackup.log 2>&1

# Every 2 minutes
*/2 * * * * /usr/local/bin/backup-mongo.sh mongodb-backups-got-unique >> /var/log/mongobackup.log 2>&1

# Every hour
0 * * * * /usr/local/bin/backup-mongo.sh mongodb-backups-got-unique >> /var/log/mongobackup.log 2>&1
```

### Restore from Backup

To restore a MongoDB backup from S3:

1. **Download the backup from S3:**
   ```bash
   aws s3 cp s3://your-bucket/mongodb-backup-20240819-143052.tar.gz /tmp/
   ```

2. **Extract the backup archive:**
   ```bash
   tar -xzf /tmp/mongodb-backup-20240819-143052.tar.gz -C /tmp/
   ```

3. **Restore the database:**
   ```bash
   mongorestore --username admin --password admin --authenticationDatabase admin /tmp/
   ```

