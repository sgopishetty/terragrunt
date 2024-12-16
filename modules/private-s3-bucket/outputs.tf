output "name" {
  description = "The name of the S3 bucket."
  value       = length(aws_s3_bucket.bucket) > 0 ? aws_s3_bucket.bucket[0].bucket : null
}

output "arn" {
  description = "The ARN of the S3 bucket."
  value       = length(aws_s3_bucket.bucket) > 0 ? aws_s3_bucket.bucket[0].arn : null
}

output "bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = length(aws_s3_bucket.bucket) > 0 ? aws_s3_bucket.bucket[0].bucket_domain_name : null
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL."
  value       = length(aws_s3_bucket.bucket) > 0 ? aws_s3_bucket.bucket[0].bucket_regional_domain_name : null
}

output "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region."
  value       = length(aws_s3_bucket.bucket) > 0 ? aws_s3_bucket.bucket[0].hosted_zone_id : null
}

output "replication_iam_role_name" {
  description = "The name of an IAM role that can be used to configure replication from various source buckets."
  value = (
    length(aws_iam_role.replication_role) > 0
    ? aws_iam_role.replication_role[0].id
    : null
  )
}

output "replication_iam_role_arn" {
  description = "The ARN of an IAM role that can be used to configure replication from various source buckets."
  value = (
    length(aws_iam_role.replication_role) > 0
    ? aws_iam_role.replication_role[0].arn
    : null
  )
}

# The following output is useful for creating dependencies across the bucket configuration resources. For example,
# when setting up replication with versioned buckets, the replica bucket must have versioning enabled before replication
# is configured.
output "bucket_is_fully_configured" {
  description = "A value that can be used to chain resources to depend on the bucket being fully configured with all the configuration resources created. The value is always true, as the bucket would be fully configured when Terraform is able to render this."
  value = (
    length(compact(flatten([
      aws_s3_bucket_accelerate_configuration.bucket[*].id,
      aws_s3_bucket_acl.bucket[*].id,
      aws_s3_bucket_cors_configuration.bucket[*].id,
      aws_s3_bucket_lifecycle_configuration.bucket[*].id,
      aws_s3_bucket_logging.bucket[*].id,
      aws_s3_bucket_object_lock_configuration.bucket[*].id,
      aws_s3_bucket_request_payment_configuration.bucket[*].id,
      aws_s3_bucket_server_side_encryption_configuration.bucket[*].id,
      aws_s3_bucket_versioning.bucket[*].id,
      aws_s3_bucket_replication_configuration.replication[*].id,
#      aws_s3_bucket_public_access_block.public_access[*].id,
      aws_s3_bucket_ownership_controls.bucket[*].id,
      aws_s3_bucket_policy.bucket_policy[*].id,
    ]))) > 0
    ? true
    : true
  )
}
