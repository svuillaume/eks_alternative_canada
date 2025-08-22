terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"  # Ohio region
}

# Simple variable for bucket name
variable "bucket_name" {
  default = "sam-s3"
}

# Random suffix to make the bucket unique
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create the S3 bucket
resource "aws_s3_bucket" "mongodb_backup_bucket" {
  bucket        = "${var.bucket_name}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name    = "MongoDB Backup Bucket"
    Project = "mongodb-backup-system"
    Purpose = "mongodb-backups"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Allow public read access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mongodb_backup_bucket.arn}/*"
      }
    ]
  })
}

# Lifecycle rules: move old objects to cheaper storage and delete after a year
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "delete_old_versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.mongodb_backup_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.mongodb_backup_bucket.arn
}

output "public_url_format" {
  value = "https://${aws_s3_bucket.mongodb_backup_bucket.bucket}.s3.us-east-2.amazonaws.com/[backup-filename]"
}
