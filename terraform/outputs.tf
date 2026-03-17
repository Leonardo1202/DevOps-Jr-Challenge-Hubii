output "bucket_name" {
  description = "Name of the S3 bucket created"
  value       = aws_s3_bucket.app_artifacts.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_artifacts.arn
}

output "bucket_region" {
  description = "AWS region where the bucket was created"
  value       = var.aws_region
}