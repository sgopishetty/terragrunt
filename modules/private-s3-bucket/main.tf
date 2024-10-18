terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # This module is compatible with AWS provider ~> 4.6.0, but we are setting the lower limit to 3.75.0 to allow for
      # easier upgrades.
      version = ">= 3.75.1, < 6.0.0"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "bucket" {
  count = var.create_resources ? 1 : 0

  bucket              = var.name
  force_destroy       = var.force_destroy
  tags                = var.tags
  object_lock_enabled = var.object_lock_enabled

  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration,
      logging,
      versioning,
      lifecycle_rule,
      cors_rule,
      grant,

      # This is referencing the rule instead of the block as recommended in the AWS provider docs:
      # https://registry.terraform.io/providers/hashicorp/aws/3.75.1/docs/resources/s3_bucket_object_lock_configuration#usage-notes
      object_lock_configuration[0].rule,
    ]
  }
}

# Optionally enable bucket acceleration.
resource "aws_s3_bucket_accelerate_configuration" "bucket" {
  count = var.create_resources && var.acceleration_status != null ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id
  status = var.acceleration_status
}

# Optionally enable bucket access control list.
resource "aws_s3_bucket_acl" "bucket" {
  count = local.create_acl && var.bucket_ownership != null && var.bucket_ownership != "BucketOwnerEnforced" ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id
  acl    = var.acl

  depends_on = [aws_s3_bucket_ownership_controls.bucket]
}

# Optionally enable CORS rules.
resource "aws_s3_bucket_cors_configuration" "bucket" {
  count = var.create_resources && length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_origins = cors_rule.value["allowed_origins"]
      allowed_methods = cors_rule.value["allowed_methods"]
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

# Optionally enable lifecycle rules. These can be used to switch storage types or delete objects based on customizable
# rules.
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count = var.create_resources && length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = lookup(rule.value, "enabled", null) == true ? "Enabled" : "Disabled"

      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload_days", null) != null ? ["once"] : []
        content {
          days_after_initiation = lookup(rule.value, "abort_incomplete_multipart_upload_days", null)
        }
      }

      # For 3.x backward compatibility:
      # Create an and filter when tags are provided, even if prefix is not provided, to match the 3.x provider logic.
      # See https://github.com/hashicorp/terraform-provider-aws/blob/v3.74.3/internal/service/s3/bucket.go#L2242-L2249
      dynamic "filter" {
        for_each = lookup(rule.value, "tags", null) != null ? ["once"] : []
        content {
          and {
            prefix = lookup(rule.value, "prefix", null)
            tags   = lookup(rule.value, "tags", null)
          }
        }
      }

      # For 3.x backward compatibility:
      # Create a prefix-only filter when tags are not provided, even if prefix is not provided, to match the 3.x
      # provider logic.
      # See https://github.com/hashicorp/terraform-provider-aws/blob/v3.74.3/internal/service/s3/bucket.go#L2242-L2249
      dynamic "filter" {
        for_each = lookup(rule.value, "tags", null) == null ? ["once"] : []
        content {
          prefix = lookup(rule.value, "prefix", null)
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", {})
        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transition", {})
        content {
          storage_class = lookup(transition.value, "storage_class")
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? ["once"] : []
        content {
          noncurrent_days = lookup(rule.value, "noncurrent_version_expiration")
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", {})
        content {
          noncurrent_days = lookup(noncurrent_version_transition.value, "days")
          storage_class   = lookup(noncurrent_version_transition.value, "storage_class")
        }
      }
    }
  }
}

# Optionally enable access logging
resource "aws_s3_bucket_logging" "bucket" {
  count = var.create_resources && var.access_logging_enabled ? 1 : 0

  bucket        = aws_s3_bucket.bucket[0].id
  target_bucket = var.access_logging_bucket

  # target_prefix was optional in provider version 3.x, but is now required so cannot be null.
  # To keep provider version 4.x support backward compatible, default to "" when var.access_logging_prefix is null.
  target_prefix = var.access_logging_prefix == null ? "" : var.access_logging_prefix
}

# Optionally enable object locking. This can be used to prevent deleting objects in this bucket for a customizable
# period of time.
resource "aws_s3_bucket_object_lock_configuration" "bucket" {
  count = var.create_resources && var.object_lock_enabled ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  dynamic "rule" {
    for_each = var.object_lock_default_retention_enabled ? ["once"] : []
    content {
      default_retention {
        mode  = var.object_lock_mode
        days  = var.object_lock_days
        years = var.object_lock_years
      }
    }
  }
}

# Optionally enable request payment configuration.
resource "aws_s3_bucket_request_payment_configuration" "bucket" {
  count = var.create_resources && var.request_payer != null ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id
  payer  = var.request_payer
}

# Optionally enable server side encryption configuration.
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count = var.create_resources && var.enable_sse && var.sse_algorithm != null ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  # Optionally enable Server Side Encryption.
  dynamic "rule" {
    for_each = var.enable_sse && var.sse_algorithm != null ? ["once"] : []

    content {
      bucket_key_enabled = var.bucket_key_enabled
      apply_server_side_encryption_by_default {
        # If a KMS key is not provided (kms_key_arn is null), the default aws/s3 key is used
        kms_master_key_id = var.kms_key_arn
        sse_algorithm     = var.sse_algorithm
      }
    }
  }
}

# Optionally enable bucket versioning.
resource "aws_s3_bucket_versioning" "bucket" {
  count = var.create_resources ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  # Optionally enable versioning. If enabled, instead of overriding objects, the S3 bucket will always create a new
  # version of each object, so all the old values are retained.
  versioning_configuration {
    status     = var.enable_versioning || var.object_lock_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE OBJECT REPLICATION
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.create_resources && var.replication_enabled ? 1 : 0

  # Must have bucket versioning enabled first.
  depends_on = [aws_s3_bucket_versioning.bucket]

  bucket = aws_s3_bucket.bucket[0].id
  role   = var.replication_role

  dynamic "rule" {
    for_each = var.replication_rules

    content {
      id       = rule.key
      status   = lookup(rule.value, "status")
      priority = lookup(rule.value, "priority", null)
      prefix   = lookup(rule.value, "prefix", null)

      destination {
        bucket        = lookup(rule.value, "destination_bucket")
        storage_class = lookup(rule.value, "destination_storage_class", null)
        account       = lookup(rule.value, "destination_account_id", null)

        dynamic "encryption_configuration" {
          for_each = lookup(rule.value, "destination_replica_kms_key_id", null) != null ? ["once"] : []
          content {
            replica_kms_key_id = lookup(rule.value, "destination_replica_kms_key_id", null)
          }
        }

        dynamic "access_control_translation" {
          for_each = lookup(rule.value, "destination_access_control_translation", false) ? ["once"] : []
          content {
            owner = "Destination"
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = lookup(rule.value, "destination_replica_kms_key_id", null) != null ? ["once"] : []

        content {
          sse_kms_encrypted_objects {
            status = "Enabled"
          }
        }
      }

      dynamic "existing_object_replication" {
        for_each = lookup(rule.value, "existing_object_replication", false) ? ["once"] : []

        content {
          status = "Enabled"
        }
      }

      dynamic "delete_marker_replication" {
        for_each = lookup(rule.value, "delete_marker_replication", false) ? ["once"] : []

        content {
          status = "Enabled"
        }
      }

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", {})

        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE IAM ROLE FOR BUCKET REPLICATION TO THIS BUCKET
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "replication_role" {
  count = var.create_resources && var.create_replication_iam_role_to_bucket ? 1 : 0

  name = (
    var.custom_iam_role_name_for_replication_role == null
    ? "allow-replicate-to-${aws_s3_bucket.bucket[0].id}"
    : var.custom_iam_role_name_for_replication_role
  )
  assume_role_policy   = data.aws_iam_policy_document.allow_s3_assume[0].json
  permissions_boundary = var.iam_role_permissions_boundary
}

resource "aws_iam_role_policy" "allow_replicate" {
  count = var.create_resources && var.create_replication_iam_role_to_bucket && local.use_inline_policies ? 1 : 0

  name   = "allow-replicate"
  role   = aws_iam_role.replication_role[0].id
  policy = data.aws_iam_policy_document.allow_replication[0].json
}

resource "aws_iam_policy" "allow_replicate" {
  count = var.create_resources && var.create_replication_iam_role_to_bucket && var.use_managed_iam_policies ? 1 : 0

  name_prefix = "allow-replicate-to-${aws_s3_bucket.bucket[0].id}"
  description = "IAM Policy to allow replication access to this bucket from specific source buckets."
  policy      = data.aws_iam_policy_document.allow_replication[0].json
}

resource "aws_iam_role_policy_attachment" "allow_replicate" {
  count = var.create_resources && var.create_replication_iam_role_to_bucket && var.use_managed_iam_policies ? 1 : 0

  role       = aws_iam_role.replication_role[0].id
  policy_arn = aws_iam_policy.allow_replicate[0].arn
}

data "aws_iam_policy_document" "allow_s3_assume" {
  count = var.create_resources ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current[0].account_id]
    }
  }
}

data "aws_iam_policy_document" "allow_replication" {
  count = var.create_resources && var.create_replication_iam_role_to_bucket ? 1 : 0

  dynamic "statement" {
    for_each = var.replication_source_buckets

    content {
      sid = "AllowReadingDetailsOf${replace(statement.value, "-", "")}"

      actions = [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket",
      ]
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${statement.value}"]
    }
  }

  dynamic "statement" {
    for_each = var.replication_source_buckets

    content {
      sid = "AllowReadingObjectsOf${replace(statement.value, "-", "")}"

      actions = [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${statement.value}/*"]
    }
  }

  statement {
    sid = "AllowReplicatingToDestination"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.bucket[0].id}/*"]
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# BLOCK ALL POSSIBILITY OF ACCIDENTALLY ENABLING PUBLIC ACCESS TO THIS BUCKET
# ----------------------------------------------------------------------------------------------------------------------

#resource "aws_s3_bucket_public_access_block" "public_access" {
#  count = var.create_resources ? 1 : 0
#
#  bucket                  = aws_s3_bucket.bucket[0].id
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A BUCKET POLICY TO CONTROL ACCESS TO THE BUCKET
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.create_resources ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id
  policy = data.aws_iam_policy_document.config_bucket_policy[0].json

#  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

data "aws_iam_policy_document" "config_bucket_policy" {
  count = var.create_resources ? 1 : 0

  # Users can provide custom rules for what permissions to grant to this bucket
  dynamic "statement" {
    for_each = var.bucket_policy_statements
    content {
      sid         = statement.key
      effect      = lookup(statement.value, "effect", null)
      actions     = lookup(statement.value, "actions", null)
      not_actions = lookup(statement.value, "not_actions", null)
      resources   = [for key in lookup(statement.value, "keys", [""]) : "${aws_s3_bucket.bucket[0].arn}${key}"]

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", {})
        content {
          type        = principals.key
          identifiers = principals.value
        }
      }

      dynamic "not_principals" {
        for_each = lookup(statement.value, "not_principals", {})
        content {
          type        = not_principals.key
          identifiers = not_principals.value
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "condition", {})
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  # The only rule we include by default is to require that all access to this bucket is over TLS
  statement {
    sid     = "AllowTLSRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.bucket[0].arn,
      "${aws_s3_bucket.bucket[0].arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE WHO OWNS OBJECTS IN THE S3 BUCKET
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "bucket" {
  count = var.create_resources && var.bucket_ownership != null ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  rule {
    object_ownership = var.bucket_ownership
  }

  # Setting the bucket attribute to the id of the bucket doesn't seem to create an implicit dependency as one might
  # expect. Without this depends_on, a "conflicting conditional operation" error may occur.
  # See: https://github.com/gruntwork-io/terraform-aws-security/pull/542
  depends_on = [aws_s3_bucket.bucket]
}

# ----------------------------------------------------------------------------------------------------------------------
# LOOKUP CALLER IDENTITY
# ----------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {
  count = var.create_resources ? 1 : 0
}

data "aws_partition" "current" {}
