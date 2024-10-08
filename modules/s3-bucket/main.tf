# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN S3 BUCKET
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"

  # This module is compatible with AWS provider ~> 4.6.0, but to make upgrading easier, we are setting 3.75.0 as the minimum version.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.75.1, < 6.0.0"
    }
  }
}

provider "aws" {
  # If we are setting up replication, use the region the user provided. Otherwise, if we're not setting up replication,
  # and the user hasn't specified a region, pick a region just so the provider block doesn't error out (the provider
  # won't be used, so the region doesn't matter in this case)
  alias  = "replica"
  region = var.replica_bucket == null && var.replica_region == null ? "us-east-1" : var.replica_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE PRIMARY BUCKET
# ---------------------------------------------------------------------------------------------------------------------
module "s3_bucket_primary" {
  source = "/github/workspace/modules/private-s3-bucket"

  name = var.primary_bucket

  # Object versioning
  enable_versioning = var.enable_versioning
  mfa_delete        = var.mfa_delete

  # Access logging
  access_logging_enabled = var.access_logging_bucket != null
  access_logging_bucket  = module.s3_bucket_logs.name
  access_logging_prefix  = var.access_logging_prefix

  # Replication
  replication_enabled = module.s3_bucket_replica.name != null
  replication_role    = var.replication_role
  # use a tautology on the replication bucket being fully configured to ensure all required configuration options are
  # set up on the replication bucket before the replication rules are setup.
  replication_rules = (
    module.s3_bucket_replica.bucket_is_fully_configured
    ? var.replication_rules
    : var.replication_rules
  )

  # CORS
  cors_rules = var.cors_rules

  # Lifecycle Rules
  lifecycle_rules = var.lifecycle_rules

  bucket_policy_statements = var.bucket_policy_statements
  bucket_ownership         = var.bucket_ownership
  acl                      = var.acl
  enable_sse               = var.enable_sse
  bucket_key_enabled       = var.bucket_key_enabled
  kms_key_arn              = var.bucket_kms_key_arn
  sse_algorithm            = var.bucket_sse_algorithm
  tags                     = var.tags
  force_destroy            = var.force_destroy_primary

  # Object Lock
  object_lock_enabled                   = var.object_lock_enabled
  object_lock_default_retention_enabled = var.object_lock_default_retention_enabled
  object_lock_mode                      = var.object_lock_mode
  object_lock_days                      = var.object_lock_days
  object_lock_years                     = var.object_lock_years
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET TO STORE ACCESS LOGS
# ---------------------------------------------------------------------------------------------------------------------
module "s3_bucket_logs" {
  source = "/github/workspace/modules/private-s3-bucket"

  create_resources = var.access_logging_bucket != null

  name                     = var.access_logging_bucket
  acl                      = "log-delivery-write"
  bucket_policy_statements = var.access_logging_bucket_policy_statements
  enable_versioning        = var.enable_versioning
  lifecycle_rules          = var.access_logging_bucket_lifecycle_rules
  mfa_delete               = var.mfa_delete
  sse_algorithm            = "AES256" # For access logging buckets, only AES256 encryption is supported
  bucket_ownership         = var.access_logging_bucket_ownership
  tags                     = var.tags
  force_destroy            = var.force_destroy_logs
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET FOR REPLICATION
# ---------------------------------------------------------------------------------------------------------------------
module "s3_bucket_replica" {
  source = "/github/workspace/modules/private-s3-bucket"

  providers = {
    aws = aws.replica
  }

  create_resources         = var.replica_bucket != null && var.replica_bucket_already_exists == false
  name                     = var.replica_bucket
  enable_versioning        = var.enable_versioning
  lifecycle_rules          = var.replica_bucket_lifecycle_rules
  mfa_delete               = var.mfa_delete
  bucket_policy_statements = var.replica_bucket_policy_statements
  bucket_ownership         = var.replica_bucket_ownership
  acl                      = var.replica_bucket_acl
  bucket_key_enabled       = var.replica_bucket_key_enabled
  enable_sse               = var.replica_enable_sse
  sse_algorithm            = var.replica_sse_algorithm
  tags                     = var.tags
  force_destroy            = var.force_destroy_replica

  # Object Lock
  object_lock_enabled                   = var.object_lock_enabled
  object_lock_default_retention_enabled = var.object_lock_default_retention_enabled
  object_lock_mode                      = var.object_lock_mode
  object_lock_days                      = var.object_lock_days
  object_lock_years                     = var.object_lock_years
}
